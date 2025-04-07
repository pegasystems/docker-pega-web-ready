package com.pega.cmc;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.Properties;

import static com.pega.cmc.VersionChecker.*;
import static org.junit.jupiter.api.Assertions.*;

public class TestVersionChecker {
    @Test
    public void basicTest() {
        TestEnvHelper env = new TestEnvHelper();
        env.put(ENV_JDBC_DRIVER_CLASS,"org.postgresql.Driver");
        env.put(ENV_JDBC_URL,"jdbc:postgresql://l43039wus.rpega.com:5432/rulesync");
        env.put(ENV_JDBC_USER,"rulesync");
        env.put(ENV_JDBC_PASSWORD,"rulesync");
        env.put(ENV_JDBC_CONN_PROPS,"");
        env.put(ENV_RULE_SCHEMA_NAME,"rules");

        VersionChecker vc = VersionChecker.createVersionChecker(env);
        System.out.println(vc.checkVersion());

    }

    @Test
    public void testConnectionPropParsing() {
        EnvHelper env = getTestEnv();
        VersionChecker vc = VersionChecker.createVersionChecker(env);

        vc.setJdbcConnectionProperties("a=1;b=2;c=3;d===;");
        Properties props = vc.parsePropertyString();

        assertEquals("1", props.getProperty("a"));
        assertEquals("2", props.getProperty("b"));
        assertEquals("3", props.getProperty("c"));
        assertEquals("==", props.getProperty("d"));

        vc.setJdbcConnectionProperties("a=1;b=2;c=3;d===");
        props = vc.parsePropertyString();

        assertEquals("1", props.getProperty("a"));
        assertEquals("2", props.getProperty("b"));
        assertEquals("3", props.getProperty("c"));
        assertEquals("==", props.getProperty("d"));
    }

    @Test
    public void testConnectionPropParsingBadProperty() {
        EnvHelper env = getTestEnv();
        VersionChecker vc = VersionChecker.createVersionChecker(env);
        vc.setJdbcConnectionProperties("a=1;b=2;c=3;d;");
        assertThrows(VersionCheckerException.class,
                () -> vc.parsePropertyString(),
                "Exception should have been thrown.");
    }

    @Test
    public void testloadMissingDriver() {
        EnvHelper env = getTestEnv();
        VersionChecker vc = VersionChecker.createVersionChecker(env);
        vc.setJdbcDriverClass("org.missingclass.Driver");
        assertThrows(VersionCheckerException.class,
                () -> vc.loadDriver(),
                "Exception should have been thrown.");
    }

    @Test
    public void testSetCredsAsProps() {
        Properties props =getCredentialProperties(null,null);
        assertNull(props.getProperty(PROP_USER));
        assertNull(props.getProperty(PROP_PASSWORD));

        props = getCredentialProperties("","");
        assertNull(props.getProperty(PROP_USER));
        assertNull(props.getProperty(PROP_PASSWORD));

        props = getCredentialProperties("user","password");
        assertEquals("user", props.getProperty(PROP_USER));
        assertEquals("password", props.getProperty(PROP_PASSWORD));
    }

    private Properties getCredentialProperties(String user, String password) {
        TestEnvHelper env = new TestEnvHelper();
        env.put(ENV_JDBC_USER, user);
        env.put(ENV_JDBC_PASSWORD, password);
        VersionChecker vc = VersionChecker.createVersionChecker(env);
        Properties props = new Properties();
        vc.addCredentialProperties(props);
        return props;
    }

    @Test
    public void testQuery() {
        TestEnvHelper env = new TestEnvHelper();
        env.put(ENV_RULE_SCHEMA_NAME, "rules");

        VersionChecker vc = VersionChecker.createVersionChecker(env);

        assertEquals("select max(pyrulesetversionid) from rules.pr4_rule_ruleset where pxObjClass='Rule-RuleSet-Version' and pyrulesetname='Pega-RULES'", vc.getQuery());
    }

    private EnvHelper getTestEnv() {
        TestEnvHelper env = new TestEnvHelper();
        env.put(ENV_JDBC_DRIVER_CLASS,"org.postgresql.Driver");
        env.put(ENV_JDBC_URL,"jdbc:postgresql://somehostname:5432/rulesync");
        env.put(ENV_JDBC_USER,"rulesync");
        env.put(ENV_JDBC_PASSWORD,"rulesync");
        env.put(ENV_JDBC_CONN_PROPS,"");
        env.put(ENV_RULE_SCHEMA_NAME,"rules");
        return env;
    }

}
