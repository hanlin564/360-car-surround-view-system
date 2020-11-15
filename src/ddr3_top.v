module ddr3_top(
    input              clk_50m            ,   //ddr3参考时钟
    input              sys_rst_n           ,   //复位,低有效
    input              sys_init_done       ,   //系统初始化完成               
    //DDR3接口信号                           
    input   [27:0]     app_addr_rd_min     ,   //读ddr3的起始地址
    input   [27:0]     app_addr_rd_max     ,   //读ddr3的结束地址
    input   [7:0]      rd_bust_len         ,   //从ddr3中读数据时的突发长度
    input   [27:0]     app_addr_wr_min     ,   //读ddr3的起始地址
    input   [27:0]     app_addr_wr_max     ,   //读ddr3的结束地址
    input   [7:0]      wr_bust_len         ,   //从ddr3中读数据时的突发长度
    // DDR3 IO接口 
    inout   [15:0]     ddr3_dq             ,   //ddr3 数据
    inout   [1:0]      ddr3_dqs_n          ,   //ddr3 dqs负
    inout   [1:0]      ddr3_dqs_p          ,   //ddr3 dqs正  
    output  [13:0]     ddr3_addr           ,   //ddr3 地址   
    output  [2:0]      ddr3_ba             ,   //ddr3 banck 选择
    output             ddr3_ras_n          ,   //ddr3 行选择
    output             ddr3_cas_n          ,   //ddr3 列选择
    output             ddr3_we_n           ,   //ddr3 读写选择
    output             ddr3_reset_n        ,   //ddr3 复位
    output  [0:0]      ddr3_ck_p           ,   //ddr3 时钟正
    output  [0:0]      ddr3_ck_n           ,   //ddr3 时钟负
    output  [0:0]      ddr3_cke            ,   //ddr3 时钟使能
    output  [0:0]      ddr3_cs_n           ,   //ddr3 片选
    output  [1:0]      ddr3_dm             ,   //ddr3_dm
    output  [0:0]      ddr3_odt            ,   //ddr3_odt      
    //用户
    input              wr_clk_1            ,   //wfifo时钟
    input              datain_valid_1      ,   //数据有效使能信号
    input   [15:0]     datain_1            ,   //有效数据 
    input              wr_load_1           ,   //输入源场信号    
    input              wr_clk_2            ,   //wfifo时钟
    input              datain_valid_2      ,   //数据有效使能信号
    input   [15:0]     datain_2            ,   //有效数据 
    input              wr_load_2           ,   //输入源场信号
    
    input              wr_clk_3            ,   //wfifo时钟
    input              datain_valid_3      ,   //数据有效使能信号
    input   [15:0]     datain_3            ,   //有效数据 
    input              wr_load_3           ,   //输入源场信号    
    input              wr_clk_4            ,   //wfifo时钟
    input              datain_valid_4      ,   //数据有效使能信号
    input   [15:0]     datain_4            ,   //有效数据 
    input              wr_load_4           ,   //输入源场信号

    input   [12:0]     h_disp              ,   //摄像头水平分辨率 
    input   [12:0]     v_disp              ,   //摄像头垂直分辨率

    input              rd_clk              ,   //rfifo的读时钟      
    input              rdata_req           ,   //请求像素点颜色数据输入  
    input              rd_load             ,   //输出源场信号
    output  [15:0]     dataout             ,   //rfifo输出数据
    output             init_calib_complete     //ddr3初始化完成信号

    );                
                      
 //wire define  
wire                  ui_clk               ;   //用户时钟
wire [27:0]           app_addr             ;   //ddr3 地址
wire [2:0]            app_cmd              ;   //用户读写命令
wire                  app_en               ;   //MIG IP核使能
wire                  app_rdy              ;   //MIG IP核空闲
wire [127:0]          app_rd_data          ;   //用户读数据
wire                  app_rd_data_end      ;   //突发读当前时钟最后一个数据 
wire                  app_rd_data_valid    ;   //读数据有效
wire [127:0]          app_wdf_data         ;   //用户写数据 
wire                  app_wdf_end          ;   //突发写当前时钟最后一个数据 
wire [15:0]           app_wdf_mask         ;   //写数据屏蔽                           
wire                  app_wdf_rdy          ;   //写空闲                               
wire                  app_sr_active        ;   //保留                                 
wire                  app_ref_ack          ;   //刷新请求                             
wire                  app_zq_ack           ;   //ZQ 校准请求                          
wire                  app_wdf_wren         ;   //ddr3 写使能                          
wire                  clk_ref_i            ;   //ddr3参考时钟                         
wire                  sys_clk_i            ;   //MIG IP核输入时钟                     
wire                  ui_clk_sync_rst      ;   //用户复位信号                         
wire [20:0]           rd_cnt               ;   //实际读地址计数                       
wire [3 :0]           state_cnt            ;   //状态计数器                           
wire [23:0]           rd_addr_cnt          ;   //用户读地址计数器                     
wire [23:0]           wr_addr_cnt          ;   //用户写地址计数器                     
wire                  rfifo_wren           ;   //从ddr3读出数据的有效使能              
wire                  init_calib_complete  ;   //ddr3初始化完成信号
wire [127:0]          rfifo_wdata_1        ;   //rfifo1输入数据  
wire [127:0]          rfifo_wdata_2        ;   //rfifo2输入数据                                                                                    
wire [10:0]           wfifo_rcount_1       ;   //wfifo1剩余数据计数 
wire [10:0]           wfifo_rcount_2       ;   //wfifo2剩余数据计数 
wire [10:0]           rfifo_wcount_1       ;   //rfifo1写进数据计数
wire [10:0]           rfifo_wcount_2       ;   //rfifo2写进数据计数 

wire [127:0]          rfifo_wdata_3        ;   //rfifo1输入数据  
wire [127:0]          rfifo_wdata_4        ;   //rfifo2输入数据                                                                                    
wire [10:0]           wfifo_rcount_3       ;   //wfifo1剩余数据计数 
wire [10:0]           wfifo_rcount_4       ;   //wfifo2剩余数据计数 
wire [10:0]           rfifo_wcount_3       ;   //rfifo1写进数据计数
wire [10:0]           rfifo_wcount_4       ;   //rfifo2写进数据计数  
                                                                                  



                                                                               
//读写模块                                                                            
 ddr3_rw u_ddr3_rw(                                                                   
    .ui_clk               (ui_clk)              ,                                     
    .ui_clk_sync_rst      (ui_clk_sync_rst)     ,                                      
    //MIG 接口                                                                        
    .init_calib_complete  (init_calib_complete) ,   //ddr3初始化完成信号                                   
    .app_rdy              (app_rdy)             ,   //MIG IP核空闲                                   
    .app_wdf_rdy          (app_wdf_rdy)         ,   //写空闲                                   
    .app_rd_data_valid    (app_rd_data_valid)   ,   //读数据有效 
    .app_rd_data          (app_rd_data)         ,   //读数据           
    .app_addr             (app_addr)            ,   //ddr3 地址                                   
    .app_en               (app_en)              ,   //MIG IP核使能                                   
    .app_wdf_wren         (app_wdf_wren)        ,   //ddr3 写使能                                    
    .app_wdf_end          (app_wdf_end)         ,   //突发写当前时钟最后一个数据                                   
    .app_cmd              (app_cmd)             ,   //用户读写命令                                                                                                                        
    //DDR3 地址参数                                                                   
    .app_addr_rd_min      (app_addr_rd_min)     ,   //读ddr3的起始地址                                  
    .app_addr_rd_max      (app_addr_rd_max)     ,   //读ddr3的结束地址                                  
    .rd_bust_len          (rd_bust_len)         ,   //从ddr3中读数据时的突发长度                                  
    .app_addr_wr_min      (app_addr_wr_min)     ,   //写ddr3的起始地址                                  
    .app_addr_wr_max      (app_addr_wr_max)     ,   //写ddr3的结束地址                                  
    .wr_bust_len          (wr_bust_len)         ,   //从ddr3中写数据时的突发长度                                  
    //用户接口                                                                        
    .rfifo_wren_1         (rfifo_wren_1)        ,   //rfifo写使能 
    .rfifo_wdata_1        (rfifo_wdata_1)       ,   //rfifo写数据 
    .rfifo_wren_2         (rfifo_wren_2)        ,   //rfifo写使能  
    .rfifo_wdata_2        (rfifo_wdata_2)       ,   //rfifo写数据
    .wfifo_rden_1         (wfifo_rden_1)        ,   //写端口FIFO1中的读使能
    .wfifo_rden_2         (wfifo_rden_2)        ,   //写端口FIFO2中的读使能  
    .rd_load              (rd_load)             ,   //输出源场信号
    .wr_load_1            (wr_load_1)           ,   //输入源场信号
    .wr_load_2            (wr_load_2)           ,   //输入源场信号    
    .wfifo_rcount_1       (wfifo_rcount_1)      ,   //wfifo剩余数据计数                  
    .rfifo_wcount_1       (rfifo_wcount_1)      ,   //rfifo写进数据计数
    .wfifo_rcount_2       (wfifo_rcount_2)      ,   //wfifo剩余数据计数                  
    .rfifo_wcount_2       (rfifo_wcount_2)      ,   //rfifo写进数据计数   
    .wr_clk_2             (wr_clk_2)            ,   //wfifo时钟 
    .wr_clk_1             (wr_clk_1)           ,             //wfifo时钟 
 
    .rfifo_wren_3         (rfifo_wren_3)        ,   //rfifo写使能 
    .rfifo_wdata_3        (rfifo_wdata_3)       ,   //rfifo写数据 
    .rfifo_wren_4         (rfifo_wren_4)        ,   //rfifo写使能  
    .rfifo_wdata_4        (rfifo_wdata_4)       ,   //rfifo写数据
    .wfifo_rden_3         (wfifo_rden_3)        ,   //写端口FIFO1中的读使能
    .wfifo_rden_4         (wfifo_rden_4)        ,   //写端口FIFO2中的读使能  
    .wr_load_3            (wr_load_3)           ,   //输入源场信号
    .wr_load_4            (wr_load_4)           ,   //输入源场信号    
    .wfifo_rcount_3       (wfifo_rcount_3)      ,   //wfifo剩余数据计数                  
    .rfifo_wcount_3       (rfifo_wcount_3)      ,   //rfifo写进数据计数
    .wfifo_rcount_4       (wfifo_rcount_4)      ,   //wfifo剩余数据计数                  
    .rfifo_wcount_4       (rfifo_wcount_4)      ,   //rfifo写进数据计数   
    .wr_clk_4             (wr_clk_4)            ,   //wfifo时钟 
    .wr_clk_3             (wr_clk_3)                //wfifo时钟             
    );
 //gowin DDR3 IP
 DDR3_Memory_Interface_Top u_DDR3_Memory_Interface_Top(
		.clk(clk_50m), 
		.rst_n(sys_rst_n), //input rst_n
		.app_burst_number(6'd0), //input [5:0] app_burst_number  7表示突发长度8
		.cmd_ready(app_rdy), //output cmd_ready
		.cmd(app_cmd), //input [2:0] cmd
		.cmd_en(app_en), //input cmd_en
		.addr(app_addr), //input [27:0] addr
		.wr_data_rdy(app_wdf_rdy), //output wr_data_rdy
		.wr_data(app_wdf_data), //input [127:0] wr_data
		.wr_data_en(app_wdf_wren), //input wr_data_en
		.wr_data_end(app_wdf_end), //input wr_data_end
		.wr_data_mask(16'b0), //input [15:0] wr_data_mask
		.rd_data(app_rd_data), //output [127:0] rd_data
		.rd_data_valid(app_rd_data_valid), //output rd_data_valid
		.rd_data_end(app_rd_data_end), //output rd_data_end
		.sr_req(), //input sr_req
		.ref_req(), //input ref_req
		.sr_ack(), //output sr_ack
		.ref_ack(), //output ref_ack
		.init_calib_complete(init_calib_complete), //output init_calib_complete
		.clk_out(ui_clk), //output clk_out
		.ddr_rst(ui_clk_sync_rst), //output ddr_rst
		.burst(1'b0), //input burst
		.O_ddr_addr(ddr3_addr), //output [13:0] O_ddr_addr
		.O_ddr_ba(ddr3_ba), //output [2:0] O_ddr_ba
		.O_ddr_cs_n(), //output O_ddr_cs_n
		.O_ddr_ras_n(ddr3_ras_n), //output O_ddr_ras_n
		.O_ddr_cas_n(ddr3_cas_n), //output O_ddr_cas_n
		.O_ddr_we_n(ddr3_we_n), //output O_ddr_we_n
		.O_ddr_clk(ddr3_ck_p), //output O_ddr_clk
		.O_ddr_clk_n(ddr3_ck_n), //output O_ddr_clk_n
		.O_ddr_cke(ddr3_cke), //output O_ddr_cke
		.O_ddr_odt(ddr3_odt), //output O_ddr_odt
		.O_ddr_reset_n(ddr3_reset_n), //output O_ddr_reset_n
		.O_ddr_dqm(ddr3_dm), //output [1:0] O_ddr_dqm
		.IO_ddr_dq(ddr3_dq), //inout [15:0] IO_ddr_dq
		.IO_ddr_dqs(ddr3_dqs_p), //inout [1:0] IO_ddr_dqs
		.IO_ddr_dqs_n(ddr3_dqs_n) //inout [1:0] IO_ddr_dqs_n
	);
                              
ddr3_fifo_ctrl_top u_ddr3_fifo_ctrl_top(
    .rst_n             (sys_rst_n &&sys_init_done),  //复位信号    
    .rd_clk            (rd_clk)                   ,  //rfifo时钟
    .clk_100           (ui_clk)                   ,  //用户时钟
    //fifo1接口信号    
    .wr_clk_1          (wr_clk_1)                 ,  //wfifo时钟    
    .datain_valid_1    (datain_valid_1)           ,  //数据有效使能信号
    .datain_1          (datain_1)                 ,  //有效数据
    .wr_load_1         (wr_load_1)                ,  //输入源场信号    
    .rfifo_din_1       (rfifo_wdata_1)            ,  //rfifo写数据
    .rfifo_wren_1      (rfifo_wren_1)             ,  //rfifo写使能
    .wfifo_rden_1      (wfifo_rden_1)             ,  //wfifo读使能
    .wfifo_rcount_1    (wfifo_rcount_1)           ,  //wfifo剩余数据计数
    .rfifo_wcount_1    (rfifo_wcount_1)           ,  //rfifo写进数据计数    
    //fifo2接口信号    
    .wr_clk_2          (wr_clk_2)                 ,  //wfifo时钟    
    .datain_valid_2    (datain_valid_2)           ,  //数据有效使能信号
    .datain_2          (datain_2)                 ,  //有效数据    
    .wr_load_2         (wr_load_2)                ,  //输入源场信号
    .rfifo_din_2       (rfifo_wdata_2)            ,  //rfifo写数据
    .rfifo_wren_2      (rfifo_wren_2)             ,  //rfifo写使能
    .wfifo_rden_2      (wfifo_rden_2)             ,  //wfifo读使能    
    .wfifo_rcount_2    (wfifo_rcount_2)           ,  //wfifo剩余数据计数
    .rfifo_wcount_2    (rfifo_wcount_2)           ,  //rfifo写进数据计数
    //fifo3接口信号    
    .wr_clk_3          (wr_clk_3)                 ,  //wfifo时钟    
    .datain_valid_3    (datain_valid_3)           ,  //数据有效使能信号
    .datain_3          (datain_3)                 ,  //有效数据
    .wr_load_3         (wr_load_3)                ,  //输入源场信号    
    .rfifo_din_3       (rfifo_wdata_3)            ,  //rfifo写数据
    .rfifo_wren_3      (rfifo_wren_3)             ,  //rfifo写使能
    .wfifo_rden_3      (wfifo_rden_3)             ,  //wfifo读使能
    .wfifo_rcount_3    (wfifo_rcount_3)           ,  //wfifo剩余数据计数
    .rfifo_wcount_3    (rfifo_wcount_3)           ,  //rfifo写进数据计数    
    //fifo4接口信号    
    .wr_clk_4          (wr_clk_4)                 ,  //wfifo时钟    
    .datain_valid_4    (datain_valid_4)           ,  //数据有效使能信号
    .datain_4          (datain_4)                 ,  //有效数据    
    .wr_load_4         (wr_load_4)                ,  //输入源场信号
    .rfifo_din_4       (rfifo_wdata_4)            ,  //rfifo写数据
    .rfifo_wren_4      (rfifo_wren_4)             ,  //rfifo写使能
    .wfifo_rden_4      (wfifo_rden_4)             ,  //wfifo读使能    
    .wfifo_rcount_4    (wfifo_rcount_4)           ,  //wfifo剩余数据计数
    .rfifo_wcount_4    (rfifo_wcount_4)           ,  //rfifo写进数据计数  
                     
    .h_disp            (h_disp)                   ,  //摄像头水平分辨率
    .v_disp            (v_disp)                   ,  //摄像头垂直分辨率
    .rd_load           (rd_load)                  ,  //输出源场信号
    .rdata_req         (rdata_req)                ,  //请求像素点颜色数据输入     
    .pic_data          (dataout)                  ,  //有效数据 
    .wfifo_dout        (app_wdf_data)                //用户写数据    

    );
      
endmodule