package com.pega.cmc;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import static com.pega.cmc.VersionChecker.*;
import static org.junit.jupiter.api.Assertions.*;

public class TestVersionChecker {
    private static final String TEST_DB_USERNAME = "pegauser";
    private static final String TEST_DB_PASSWORD = "pegapassword";
    private static final String MAX_VERSION = "08-25-02";

    @BeforeAll
    public static void setUp() throws SQLException {
        Connection c = DriverManager.getConnection("jdbc:h2:mem:testdb;INIT=CREATE SCHEMA IF NOT EXISTS rules", TEST_DB_USERNAME, TEST_DB_PASSWORD);
        try ( Statement s = c.createStatement(); ){
            s.execute("create schema if not exists rules");
            s.execute("create table rules.pr4_rule_ruleset(pyrulesetversionid varchar(32), pxObjClass varchar(32), pyrulesetname varchar(32))");
            s.execute("insert into rules.pr4_rule_ruleset (pyrulesetversionid, pxObjClass, pyrulesetname) values ('" + MAX_VERSION + "', 'Rule-RuleSet-Version', 'Pega-RULES')");
            s.execute("insert into rules.pr4_rule_ruleset (pyrulesetversionid, pxObjClass, pyrulesetname) values ('08-24-02', 'Rule-RuleSet-Version', 'Pega-RULES')");
            s.execute("insert into rules.pr4_rule_ruleset (pyrulesetversionid, pxObjClass, pyrulesetname) values ('07-30-10', 'Rule-RuleSet-Version', 'Pega-RULES')");
            s.execute("insert into rules.pr4_rule_ruleset (pyrulesetversionid, pxObjClass, pyrulesetname) values ('06-01-10', 'Rule-RuleSet-Version', 'Pega-RULES')");
            s.execute("insert into rules.pr4_rule_ruleset (pyrulesetversionid, pxObjClass, pyrulesetname) values ('05-04-02', 'Rule-RuleSet-Version', 'Pega-RULES')");
        }
    }


    @Test
    public void testQueryExecution() {
        TestEnvHelper env = new TestEnvHelper();
        env.put(ENV_JDBC_DRIVER_CLASS, "org.h2.Driver");
        env.put(ENV_JDBC_URL, "jdbc:h2:mem:testdb");
        env.put(ENV_JDBC_USER, TEST_DB_USERNAME);
        env.put(ENV_JDBC_PASSWORD, TEST_DB_PASSWORD);
        env.put(ENV_JDBC_CONN_PROPS, "");
        env.put(ENV_RULE_SCHEMA_NAME, "rules");
        VersionChecker vc = VersionChecker.createVersionChecker(env);

        String maxVersion = vc.checkVersion();

        assertEquals(MAX_VERSION, maxVersion);
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
        env.put(ENV_JDBC_URL,"jdbc:postgresql://somehostname:5432/example-dbname");
        env.put(ENV_JDBC_USER,"example_username");
        env.put(ENV_JDBC_PASSWORD,"example_password");
        env.put(ENV_JDBC_CONN_PROPS,"");
        env.put(ENV_RULE_SCHEMA_NAME,"rules");
        return env;
    }


}
