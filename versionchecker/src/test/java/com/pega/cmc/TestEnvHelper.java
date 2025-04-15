package com.pega.cmc;

import java.util.HashMap;
import java.util.Map;

public class TestEnvHelper implements EnvHelper{

    private Map<String, String> env = new HashMap<>();

    public void put(String key, String value) {
        env.put(key, value);
    }

    @Override
    public String getEnvVar(String envVar) {
        return env.get(envVar);
    }
}
