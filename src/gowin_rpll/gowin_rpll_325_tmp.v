//Copyright (C)2014-2020 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.6.02Beta
//Part Number: GW2A-LV55PG484C8/I7
//Created Time: Sat Nov 14 16:49:00 2020

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL_325 your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .reset(reset_i), //input reset
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
