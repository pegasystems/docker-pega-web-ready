


pluginManagement{
    val artifactoryURL: String? by settings
    val artifactoryUser: String? by settings
    val artifactoryPassword: String? by settings
    val customMavenUrl: String? by settings
    val customMavenUser: String? by settings
    val customMavenPassword: String? by settings

    if(artifactoryURL != null) {
        repositories {
            maven {
                setUrl("${artifactoryURL}/gradle-plugins")
                credentials {
                    username = artifactoryUser
                    password = artifactoryPassword
                }
                metadataSources {
                    mavenPom()
                    gradleMetadata()
                }
            }
            maven {
                setUrl("${artifactoryURL}/repo2")
                credentials {
                    username = artifactoryUser
                    password = artifactoryPassword
                }
                metadataSources {
                    mavenPom()
                    gradleMetadata()
                }
            }
        }
    } else if(customMavenUrl != null){
        repositories{
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
        }
    }
}


include("versionchecker")
