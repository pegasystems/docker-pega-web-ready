plugins {
    id("java")
}


val testOutputFile = "${layout.buildDirectory.get().asFile.absolutePath}/platform_version.txt"


dependencies {
    testImplementation(platform("org.junit:junit-bom:5.14.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testImplementation("com.h2database:h2:2.4.240")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(11)
    }
}

tasks.test{
    useJUnitPlatform()

    environment (
        "OUTPUTFILE" to testOutputFile,
        "JDBC_CLASS" to "org.h2.Driver",
        "JDBC_URL" to "jdbc:h2:mem:testdb",
        "SECRET_DB_USERNAME" to "pegauser",
        "SECRET_DB_PASSWORD" to "pegapassword",
        "JDBC_CONNECTION_PROPERTIES" to "",
        "RULES_SCHEMA" to "rules"
    )
}
