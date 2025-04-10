package com.pega.cmc;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.Optional;

public class TestDBType {

    private static final String UNSUPPORTED_DB_DESCRIPTOR = "derby";

    @Test
    public void testIsValid() {
        Assertions.assertTrue(DBType.isValid(DBType.POSTGRES.getTypeDescriptor()));
        Assertions.assertTrue(DBType.isValid(DBType.MSSQL.getTypeDescriptor()));
        Assertions.assertTrue(DBType.isValid(DBType.DB2LUW.getTypeDescriptor()));
        Assertions.assertTrue(DBType.isValid(DBType.DB2ZOS.getTypeDescriptor()));
        Assertions.assertTrue(DBType.isValid(DBType.ORACLE.getTypeDescriptor()));
        Assertions.assertTrue(DBType.isValid(DBType.H2.getTypeDescriptor()));

        Assertions.assertFalse(DBType.isValid(UNSUPPORTED_DB_DESCRIPTOR));
    }

    @Test
    public void testGetDBType() {
        assertDBTypeOptional(DBType.POSTGRES, DBType.getDBType(DBType.POSTGRES.getTypeDescriptor()));
        assertDBTypeOptional(DBType.MSSQL, DBType.getDBType(DBType.MSSQL.getTypeDescriptor()));
        assertDBTypeOptional(DBType.DB2LUW, DBType.getDBType(DBType.DB2LUW.getTypeDescriptor()));
        assertDBTypeOptional(DBType.DB2ZOS, DBType.getDBType(DBType.DB2ZOS.getTypeDescriptor()));
        assertDBTypeOptional(DBType.ORACLE, DBType.getDBType(DBType.ORACLE.getTypeDescriptor()));
        assertDBTypeOptional(DBType.H2, DBType.getDBType(DBType.H2.getTypeDescriptor()));

        Assertions.assertFalse(DBType.getDBType(UNSUPPORTED_DB_DESCRIPTOR).isPresent());
    }

    private void assertDBTypeOptional(DBType expectedDbType, Optional<DBType> dbType) {
        Assertions.assertTrue(dbType.isPresent());
        Assertions.assertEquals(expectedDbType, dbType.get());
    }
}
