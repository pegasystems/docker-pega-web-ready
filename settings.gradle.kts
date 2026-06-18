


pluginManagement{
    val customMavenUrl: String? by settings
    val customMavenUser: String? by settings
    val customMavenPassword: String? by settings

    if(customMavenUrl != null){
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
