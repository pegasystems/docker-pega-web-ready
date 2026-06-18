import com.bmuschko.gradle.docker.tasks.container.DockerCreateContainer
import com.bmuschko.gradle.docker.tasks.container.DockerLogsContainer
import com.bmuschko.gradle.docker.tasks.container.DockerRemoveContainer
import com.bmuschko.gradle.docker.tasks.container.DockerStartContainer
import com.bmuschko.gradle.docker.tasks.image.DockerBuildImage
import com.bmuschko.gradle.docker.tasks.image.DockerPullImage
import java.net.URI
import java.nio.file.attribute.PosixFilePermission
import kotlin.io.path.createDirectories
import kotlin.io.path.deleteIfExists
import kotlin.io.path.outputStream
import kotlin.io.path.setPosixFilePermissions


plugins{
    base
    id("com.bmuschko.docker-remote-api") version "10.0.0"
}

interface ExecOperationsProvider {
    @Inject
    fun getExecOperations(): ExecOperations
}

allprojects{
    val customMavenUrl: String? by project
    val customMavenUser: String? by project
    val customMavenPassword: String? by project

    repositories {
        if(customMavenUrl != null){
            maven {
                setUrl(customMavenUrl!!)
                credentials {
                    customMavenUser?.let{
                        username = it
                    }
                    customMavenPassword?.let{
                        password = it
                    }
                }
                metadataSources {
                    mavenPom()
                    gradleMetadata()
                }
            }
        } else {
            mavenCentral()
        }
    }
}

version = "4.0.0" //TODO determine versioning strategy

evaluationDependsOnChildren()
val prometheus: Configuration by configurations.creating{
    isTransitive = false
}
val bcfips: Configuration by configurations.creating{
    isTransitive = false
}

dependencies{
    prometheus("io.prometheus.jmx:jmx_prometheus_javaagent:0.18.0")

    // Updating Bouncy Castle jars versions below?  As these are used for FIPS 140-3 support, the versions below should
    // only be replaced with FIPS certified library versions.  See https://www.bouncycastle.org/download/bouncy-castle-java-fips/#latest --
    // paying particular attention to the "Distribution Files (JAR Format)".  The jars below correspond to BC-FJA 2.0.0.
    bcfips("org.bouncycastle:bc-fips:2.0.0")
    bcfips("org.bouncycastle:bctls-fips:2.0.19")
    bcfips("org.bouncycastle:bcutil-fips:2.0.3")
    bcfips("org.bouncycastle:bc-rng-jent:1.3.6")
}

val downloadContainerStructureTestBinary by tasks.registering {
    val outputFile = layout.buildDirectory.file("bin/container-structure-test")
    outputs.file(outputFile)

    doLast {
        val realOutputFile = outputFile.get().asFile.toPath()
        realOutputFile.deleteIfExists()
        realOutputFile.parent.createDirectories()

        URI("https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64").toURL()
            .openStream().use { inStr ->
                realOutputFile.outputStream().use { outStr ->
                    inStr.copyTo(outStr)
                }
            }

        realOutputFile.setPosixFilePermissions(
            setOf(
                PosixFilePermission.OWNER_READ,
                PosixFilePermission.OWNER_WRITE,
                PosixFilePermission.OWNER_EXECUTE,
            )
        )
    }
}

val detemplatizeImageVersion: String by project
val imageName: String by project

fun createBaseImageIntrospectionTasks(
    uniqueName: String,
    baseImage: String,
    pullTask: TaskProvider<DockerPullImage>,
    vararg command: String,
) : TaskProvider<DockerLogsContainer>{

    val createContainerTask = tasks.register<DockerCreateContainer>("createContainer_$uniqueName"){
        dependsOn(pullTask)
        targetImageId(baseImage)
        entrypoint = command.toList()
    }

    val startContainerTask = tasks.register<DockerStartContainer>("startContainer_$uniqueName"){
        dependsOn(createContainerTask)

        targetContainerId(createContainerTask.get().containerId)
    }

    val logsTask = tasks.register<DockerLogsContainer>("logsContainer_$uniqueName"){
        dependsOn(startContainerTask)
        targetContainerId(startContainerTask.get().containerId)
        follow = true
        tailAll = true

        stdErr = false
        sink = layout.buildDirectory.file("introspect/$uniqueName.txt")

        doFirst {
            if (sink.get().asFile.exists()){
                delete(sink)
            }
        }
    }

    val removeContainerTask = tasks.register<DockerRemoveContainer>("removeContainer_$uniqueName"){
        targetContainerId(logsTask.get().containerId)
    }

    logsTask.configure {
        finalizedBy(removeContainerTask)
    }

    return logsTask
}

fun extractLogContent(task: TaskProvider<DockerLogsContainer>): String{
    return task.get().sink.get().asFile.readText()
}

//createBaseImageIntrospectionTasks("test", "ubuntu:26.04", listOf("bash", "-c", "echo 'test'"))

val jdk11BaseImage: String by project
val jdk17BaseImage: String by project
val jdk21BaseImage: String by project

val images = mapOf(
    jdk11BaseImage to "jdk11",
    jdk17BaseImage to "jdk17",
    jdk21BaseImage to "jdk21",
)

val copyDockerSources by tasks.registering(Copy::class){
    from(file("src"))
    val targetDir = layout.buildDirectory.dir("docker")
    into(layout.buildDirectory.dir("docker"))
    doFirst {
        if(targetDir.get().asFile.exists()){
            delete(targetDir)
        }
    }
}

val copyPrometheusJar by tasks.registering(Copy::class){
    mustRunAfter(copyDockerSources)
    from(prometheus)
    val targetDir = layout.buildDirectory.dir("docker/prometheus")
    into(targetDir)

    rename("jmx_prometheus_javaagent-.*[.]jar", "jmx_prometheus_javaagent.jar")
    doFirst {
        if(targetDir.get().asFile.exists()){
            delete(targetDir)
        }
    }
}

val copyBcFipsJars by tasks.registering(Copy::class){
    mustRunAfter(copyDockerSources)
    from(bcfips)
    val targetDir = layout.buildDirectory.dir("docker/bcfips")
    into(targetDir)
    doFirst {
        if(targetDir.get().asFile.exists()){
            delete(targetDir)
        }
    }
}

val copyVersionCheckerJar by tasks.registering(Copy::class){
    val jarTask = project("versionchecker").tasks["jar"] as Jar

    dependsOn(jarTask)
    mustRunAfter(copyDockerSources)
    from(jarTask.outputs)

    val targetDir = layout.buildDirectory.dir("docker/versionchecker")
    rename("versionchecker-.*[.]jar", "versionchecker.jar")
    into(targetDir)
    doFirst {
        if(targetDir.get().asFile.exists()){
            delete(targetDir)
        }
    }
}

images.forEach { (baseImage, tag) ->

    val pullTask = tasks.register<DockerPullImage>("pullImage_$tag"){
        image = baseImage
    }

    val catalinaHomeTask = createBaseImageIntrospectionTasks(
        "catalina_$tag", baseImage, pullTask,
        "/bin/bash", "-c",  "realpath \$CATALINA_HOME | tr -d '[:cntrl:]'")
    val caCertsTask = createBaseImageIntrospectionTasks(
        "cacerts_$tag", baseImage, pullTask,
        "/bin/bash", "-c",  "realpath \$JAVA_HOME/lib/security/cacerts | tr -d '[:cntrl:]'")
    val javaVersionTask = createBaseImageIntrospectionTasks(
        "javaVersion_$tag", baseImage, pullTask,
        "/bin/bash", "-c",  "\$JAVA_HOME/bin/java --full-version | awk '{print \$NF}'")
    val tomcatVersionTask = createBaseImageIntrospectionTasks(
        "tomcatVersion_$tag", baseImage, pullTask,
        "/bin/bash", "-c",  "\$CATALINA_HOME/bin/version.sh | grep 'Server number:' | awk '{print \$NF}'")

    val buildArgProvider = provider {
        mutableMapOf(
            "CATALINA_REAL_PATH" to extractLogContent(catalinaHomeTask),
            "CACERTS_REAL_PATH" to extractLogContent(caCertsTask),
            "BASE_TOMCAT_IMAGE" to baseImage,
            "DETEMPLATIZE_IMAGE_VERSION" to detemplatizeImageVersion,
            "JAVA_VERSION" to extractLogContent(javaVersionTask),
            "TOMCAT_VERSION" to extractLogContent(tomcatVersionTask),
            "TOMCAT_MAJOR_VERSION" to if(tag == "jdk21"){
                "10"
            } else {
                "9"
            },
            "CATALINA_PATH_SUBSTITUTION" to extractLogContent(catalinaHomeTask).replace("/", "\\/"),
        )
    }

    val buildTask = tasks.register<DockerBuildImage>("buildImage_$tag"){
        dependsOn(pullTask, catalinaHomeTask, caCertsTask, javaVersionTask, tomcatVersionTask,
            copyDockerSources, copyPrometheusJar, copyBcFipsJars, copyVersionCheckerJar)
        images = setOf("$imageName:4-$tag")
        if(tag == "jdk17"){
            images.add("$imageName:latest")
        }

        // There's a separate pull task so the pre-build introspection has access to the image
        pull = false
        buildArgs.set(buildArgProvider)

        inputDir = layout.buildDirectory.dir("docker")
    }

    tasks.assemble{
        dependsOn(buildTask)
    }

    val testTask = tasks.register("testImage_$tag"){
        dependsOn(buildTask, downloadContainerStructureTestBinary)
        doLast {
            val execOperations = objects.newInstance<ExecOperationsProvider>().getExecOperations()

            val image = buildTask.get().imageId.get()

            logger.quiet(image)
            val testBinary = downloadContainerStructureTestBinary.get().outputs.files.singleFile
            execOperations.exec {
                commandLine(
                    testBinary.absolutePath, "test", "--image",
                    image, "--config",
                    "src/tests/pega-web-ready-release-testcases.yaml"
                )


            }


            execOperations.exec {
                commandLine(
                    testBinary.absolutePath, "test", "--image",
                    image, "--config",
                    "src/tests/pega-web-ready-release-testcases_${tag}_version.yaml"
                )
            }
        }
    }
    tasks.check{
        dependsOn(testTask)
    }

    if(tag == "jdk11"){
        val buildQualityTask = tasks.register<DockerBuildImage>("buildQualityTestImage_$tag"){
            dependsOn(pullTask, catalinaHomeTask, caCertsTask, javaVersionTask, tomcatVersionTask,
                copyDockerSources, copyPrometheusJar, copyBcFipsJars, copyVersionCheckerJar)
            images = setOf("qualitytest")

            // There's a separate pull task so the pre-build introspection has access to the image
            pull = false
            buildArgs.set(buildArgProvider)
            target = "qualitytest"

            inputDir = layout.buildDirectory.dir("docker")
        }

        tasks.assemble{
            dependsOn(buildQualityTask)
        }

        val testQualityTask = tasks.register("testQualityImage_$tag"){
            dependsOn(buildQualityTask, downloadContainerStructureTestBinary)
            doLast {
                val execOperations = objects.newInstance<ExecOperationsProvider>().getExecOperations()

                val image = buildQualityTask.get().imageId
                val testBinary = downloadContainerStructureTestBinary.get().outputs.files.singleFile
                execOperations.exec {
                    commandLine(
                        testBinary.absolutePath, "test", "--image",
                        image.get(), "--config",
                        "src/tests/pega-web-ready-testcases.yaml"
                    )


                }
            }
        }
        tasks.check{
            dependsOn(testQualityTask)
        }
    }

}

val sourceRegistryUrl: String by project
val sourceRegistryUser: String by project
val sourceRegistryPassword: String by project


docker{
    if(sourceRegistryUser.isNotEmpty()){
        registryCredentials {
            url = sourceRegistryUrl
            username = sourceRegistryUser
            password = sourceRegistryPassword
        }
    }

}
