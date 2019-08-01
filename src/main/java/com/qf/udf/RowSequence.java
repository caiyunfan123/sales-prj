package com.qf.udf;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDF;
import org.apache.hadoop.hive.ql.udf.UDFType;
import org.apache.hadoop.io.LongWritable;

/**
 * Description：xxxx<br/>
 * Copyright (c) ， 2018， Jansonxu <br/>
 * This program is protected by copyright laws. <br/>
 * Date： 2019年07月31日
 *
 * @author 徐文波
 * @version : 1.0
 */
@Description(name = "row_sequence",
        value = "_FUNC_() - Returns a generated row sequence number starting from 1")
@UDFType(deterministic = false)
public class RowSequence extends UDF {
    private LongWritable result = new LongWritable();

    public RowSequence() {
        result.set(0);
    }

    /**
     * 计算器，每次累加1
     *
     * @return
     */
    public LongWritable evaluate() {
        result.set(result.get() + 1);
        return result;
    }
}
