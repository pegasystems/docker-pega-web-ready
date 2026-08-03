import com.bmuschko.gradle.docker.tasks.container.DockerCreateContainer
import com.bmuschko.gradle.docker.tasks.container.DockerLogsContainer
import com.bmuschko.gradle.docker.tasks.container.DockerRemoveContainer
import com.bmuschko.gradle.docker.tasks.container.DockerStartContainer
import com.bmuschko.gradle.docker.tasks.image.DockerBuildImage
import com.bmuschko.gradle.docker.tasks.image.DockerPullImage
import java.net.URI
import java.nio.file.attribute.PosixFilePermission
import java.util.Properties
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
    val artifactoryUrl: String? by project
    val artifactoryUser: String? by project
    val artifactoryPassword: String? by project
    val customMavenUrl: String? by project
    val customMavenUser: String? by project
    val customMavenPassword: String? by project

    val effectiveMavenUrl = artifactoryUrl ?: customMavenUrl
    val effectiveMavenUser = artifactoryUser ?: customMavenUser
    val effectiveMavenPassword = artifactoryPassword ?: customMavenPassword

    repositories {
        if(effectiveMavenUrl != null){
            maven {
                setUrl(effectiveMavenUrl)
                credentials {
                    effectiveMavenUser?.let{
                        username = it
                    }
                    effectiveMavenPassword?.let{
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

val dockerRegistryUser: String by project
val dockerRegistryPassword: String by project

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
    // paying particular attention to the "Distribution Files (JAR Format)".  The jars below correspond to BC-FJA 2.1.3.
    bcfips("org.bouncycastle:bc-fips:2.1.3")
    bcfips("org.bouncycastle:bctls-fips:2.1.24")
    bcfips("org.bouncycastle:bcutil-fips:2.1.7")
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
enum class JdkVersion(val jdkString: String){
    JDK11("jdk11"), JDK17("jdk17"), JDK21("jdk21")
}

enum class TomcatVersion(val versionString: String){
    TOMCAT_9("9"), TOMCAT_10("10")
}

data class ImageDef(
    val tag: String,
    val baseImage: String,
    val jdk: JdkVersion,
    val tomcat: TomcatVersion,
    val registryUrl: String?
)

val imageConfigFile = if(gradle.parent == null){
    file("docker-pega-web-ready.properties")
} else {
    gradle.parent!!.rootProject.file("docker-pega-web-ready.properties")
}

val imageProps = Properties()
imageConfigFile.inputStream().use {
    imageProps.load(it)
}


val imageDefs = imageProps.getProperty("tags").splitToSequence(",").map{ tag ->
    ImageDef(
        tag = tag,
        baseImage = imageProps.getProperty("$tag.baseImage"),
        jdk = JdkVersion.entries.find{ it.jdkString == imageProps.getProperty("$tag.jdk")}
            ?: throw RuntimeException("Couldn't find jdk for $tag"),
        tomcat = TomcatVersion.entries.find{ it.versionString == imageProps.getProperty("$tag.tomcat")}
            ?: throw RuntimeException("Couldn't find tomcat for $tag"),
        registryUrl = imageProps.getProperty("$tag.registryUrl").takeIf { !it.isNullOrBlank() },
    )
}.toList()

val latestTag: String = imageProps.getProperty("latestTag")
val qualityCheckTag: String = imageProps.getProperty("qualityCheckTag")

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

imageDefs.forEach { (tag, baseImage, jdk, tomcat, registryUrl) ->

    val pullTask = tasks.register<DockerPullImage>("pullImage_$tag"){
        image = baseImage

        if(registryUrl != null){
            registryCredentials {
                url.set(registryUrl)
                username.set(dockerRegistryUser)
                password.set(dockerRegistryPassword)
            }
        }
    }

    val catalinaHomeTask = createBaseImageIntrospectionTasks(
        "catalina_$tag", baseImage, pullTask,
        "/bin/bash", "-c", $$"realpath $CATALINA_HOME | tr -d '[:cntrl:]'"
    )
    val caCertsTask = createBaseImageIntrospectionTasks(
        "cacerts_$tag", baseImage, pullTask,
        "/bin/bash", "-c", $$"realpath $JAVA_HOME/lib/security/cacerts | tr -d '[:cntrl:]'"
    )
    val javaVersionTask = createBaseImageIntrospectionTasks(
        "javaVersion_$tag", baseImage, pullTask,
        "/bin/bash", "-c", $$"$JAVA_HOME/bin/java --full-version | awk '{print $NF}'"
    )
    val tomcatVersionTask = createBaseImageIntrospectionTasks(
        "tomcatVersion_$tag", baseImage, pullTask,
        "/bin/bash", "-c", $$"$CATALINA_HOME/bin/version.sh | grep 'Server number:' | awk '{print $NF}'"
    )

    val buildArgProvider = provider {
        mutableMapOf(
            "CATALINA_REAL_PATH" to extractLogContent(catalinaHomeTask),
            "CACERTS_REAL_PATH" to extractLogContent(caCertsTask),
            "BASE_TOMCAT_IMAGE" to baseImage,
            "DETEMPLATIZE_IMAGE_VERSION" to detemplatizeImageVersion,
            "JAVA_VERSION" to extractLogContent(javaVersionTask),
            "TOMCAT_VERSION" to extractLogContent(tomcatVersionTask),
            "TOMCAT_MAJOR_VERSION" to tomcat.versionString,
            "CATALINA_PATH_SUBSTITUTION" to extractLogContent(catalinaHomeTask).replace("/", "\\/"),
        )
    }

    val buildTask = tasks.register<DockerBuildImage>("buildImage_$tag"){
        dependsOn(pullTask, catalinaHomeTask, caCertsTask, javaVersionTask, tomcatVersionTask,
            copyDockerSources, copyPrometheusJar, copyBcFipsJars, copyVersionCheckerJar)
        images = setOf("$imageName:4-$tag")
        if(tag == latestTag){
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
                    "src/tests/pega-web-ready-release-testcases_${jdk.jdkString}_version.yaml"
                )
            }
        }
    }
    tasks.check{
        dependsOn(testTask)
    }

    if(tag == qualityCheckTag){
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
