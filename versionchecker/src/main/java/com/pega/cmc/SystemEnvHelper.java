package com.pega.cmc;

public class SystemEnvHelper implements EnvHelper {
    @Override
    public String getEnvVar(String envVar) {
        return System.getenv(envVar);
    }
}
