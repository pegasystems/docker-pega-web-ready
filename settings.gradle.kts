


pluginManagement{
    val artifactoryURL: String? by settings
    val artifactoryUser: String? by settings
    val artifactoryPassword: String? by settings
    val customMavenUrl: String? by settings
    val customMavenUser: String? by settings
    val customMavenPassword: String? by settings

    val effectiveMavenUrl = artifactoryURL ?: customMavenUrl
    val effectiveMavenUser = artifactoryUser ?: customMavenUser
    val effectiveMavenPassword = artifactoryPassword ?: customMavenPassword

    if(effectiveMavenUrl != null){
        repositories{
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
        }
    }
}


include("versionchecker")
