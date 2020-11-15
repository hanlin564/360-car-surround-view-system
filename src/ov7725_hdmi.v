module ov7725_hdmi(    
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
    //摄像头1接口                       
    input                 cam_pclk_1     ,  //cmos 数据像素时钟
    input                 cam_vsync_1    ,  //cmos 场同步信号
    input                 cam_href_1     ,  //cmos 行同步信号
    input   [7:0]         cam_data_1     ,  //cmos 数据
    output                cam_rst_n_1    ,  //cmos 复位信号，低电平有效
    output                cam_sgm_ctrl_1 ,  //引脚未分配※※※电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl_1      ,  //cmos SCCB_SCL线
    inout                 cam_sda_1      ,  //cmos SCCB_SDA线
    //摄像头2接口     
    input                 cam_pclk_2     ,  //cmos 数据像素时钟
    input                 cam_vsync_2    ,  //cmos 场同步信号
    input                 cam_href_2     ,  //cmos 行同步信号
    input   [7:0]         cam_data_2     ,  //cmos 数据
    output                cam_rst_n_2    ,  //cmos 复位信号，低电平有效
    output                cam_sgm_ctrl_2     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl_2      ,  //cmos SCCB_SCL线
    inout                 cam_sda_2      ,  //cmos SCCB_SDA线   
    //摄像头3接口                       
    input                 cam_pclk_3     ,  //cmos 数据像素时钟
    input                 cam_vsync_3    ,  //cmos 场同步信号
    input                 cam_href_3     ,  //cmos 行同步信号
    input   [7:0]         cam_data_3     ,  //cmos 数据
    output                cam_rst_n_3    ,  //cmos 复位信号，低电平有效
    output                cam_sgm_ctrl_3 ,  //引脚未分配※※※电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl_3      ,  //cmos SCCB_SCL线
    inout                 cam_sda_3      ,  //cmos SCCB_SDA线
    //摄像头4接口                       
    input                 cam_pclk_4     ,  //cmos 数据像素时钟
    input                 cam_vsync_4    ,  //cmos 场同步信号
    input                 cam_href_4     ,  //cmos 行同步信号
    input   [7:0]         cam_data_4     ,  //cmos 数据
    output                cam_rst_n_4    ,  //cmos 复位信号，低电平有效
    output                cam_sgm_ctrl_4 ,  //引脚未分配※※※电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl_4      ,  //cmos SCCB_SCL线
    inout                 cam_sda_4      ,  //cmos SCCB_SDA线 
     
    // DDR3                            
    inout   [15:0]        ddr3_dq        ,  //DDR3 数据
    inout   [1:0]         ddr3_dqs_n     ,  //DDR3 dqs负
    inout   [1:0]         ddr3_dqs_p     ,  //DDR3 dqs正  
    output  [13:0]        ddr3_addr      ,  //DDR3 地址   
    output  [2:0]         ddr3_ba        ,  //DDR3 banck 选择
    output                ddr3_ras_n     ,  //DDR3 行选择
    output                ddr3_cas_n     ,  //DDR3 列选择
    output                ddr3_we_n      ,  //DDR3 读写选择
    output                ddr3_reset_n   ,  //DDR3 复位
    output  [0:0]         ddr3_ck_p      ,  //DDR3 时钟正
    output  [0:0]         ddr3_ck_n      ,  //DDR3 时钟负
    output  [0:0]         ddr3_cke       ,  //DDR3 时钟使能
    output  [0:0]         ddr3_cs_n      ,  //DDR3 片选
    output  [1:0]         ddr3_dm        ,  //DDR3_dm
    output  [0:0]         ddr3_odt       ,  //DDR3_odt									   
    //hdmi接口                           
    output                tmds_clk_p     ,  // TMDS 时钟通道
    output                tmds_clk_n     ,
    output  [2:0]         tmds_data_p    ,  // TMDS 数据通道
    output  [2:0]         tmds_data_n    
    );                                 

parameter  V_CMOS_DISP = 11'd480;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd640;                 //CMOS分辨率--列						   
							   
//wire define                          
wire         clk_50m                   ;  //50mhz时钟
wire         locked                    ;  //时钟锁定信号
wire         lock1                     ;
wire         lock2                     ;
wire         lock3                     ;
wire        cam_xclk_1                  ;
wire        cam_xclk_2                  ;
wire        clk_325m                    ;
wire        clk_30                      ;
wire        clk_65m                     ;
wire         rst_n                     ;  //全局复位 								    
wire         i2c_exec                  ;  //I2C触发执行信号
wire  [23:0] i2c_data                  ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire         cam_init_done             ;  //摄像头初始化完成
wire         i2c_done                  ;  //I2C寄存器配置完成信号
wire         i2c_dri_clk               ;  //I2C操作时钟								    
wire         wr_en                     ;  //DDR3控制器模块写使能
wire         rdata_req                 ;  //DDR3控制器模块读使能
wire  [15:0] rd_data                   ;  //DDR3控制器模块读数据
wire         cmos_frame_valid_1        ;  //数据1有效使能信号
wire  [15:0] wr_data_1                 ;  //DDR3控制器模块写数据1
wire         cmos_frame_valid_2        ;  //数据2有效使能信号
wire  [15:0] wr_data_2                 ;  //DDR3控制器模块写数据2
wire         cmos_frame_valid_3        ;  
wire  [15:0] wr_data_3                 ;  
wire         cmos_frame_valid_4        ;  
wire  [15:0] wr_data_4                 ;  
wire         init_calib_complete       ;  //DDR3初始化完成init_calib_complete
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire         clk_200m                  ;  //ddr3参考时钟
wire         cmos_frame_vsync_1        ;  //输出帧1有效场同步信号
wire         cmos_frame_vsync_2        ;  //输出帧2有效场同步信号
wire         cmos_frame_vsync_3        ;  
wire         cmos_frame_vsync_4        ;  
wire         lcd_de                    ;  //LCD 数据输入使能
wire         cmos_frame_href           ;  //输出帧有效行同步信号 
wire  [27:0] app_addr_rd_min           ;  //读DDR3的起始地址
wire  [27:0] app_addr_rd_max           ;  //读DDR3的结束地址
wire  [7:0]  rd_bust_len               ;  //从DDR3中读数据时的突发长度
wire  [27:0] app_addr_wr_min           ;  //写DDR3的起始地址
wire  [27:0] app_addr_wr_max           ;  //写DDR3的结束地址
wire  [7:0]  wr_bust_len               ;  //从DDR3中写数据时的突发长度
wire  [9:0]  pixel_xpos_w              ;  //像素点横坐标
wire  [9:0]  pixel_ypos_w              ;  //像素点纵坐标   
wire         lcd_clk                   ;  //分频产生的LCD 采样时钟
wire  [12:0] h_disp                    ;  //LCD屏水平分辨率
wire  [12:0] v_disp                    ;  //LCD屏垂直分辨率     
wire  [10:0] h_pixel                   ;  //存入ddr3的水平分辨率        
wire  [10:0] v_pixel                   ;  //存入ddr3的屏垂直分辨率 
wire  [15:0] lcd_id                    ;  //LCD屏的ID号
wire  [27:0] ddr3_addr_max             ;  //存入DDR3的最大读写地址 
wire         i2c_rh_wl                 ;  //I2C读写控制信号             
wire  [7:0]  i2c_data_r                ;  //I2C读数据 
wire  [12:0] total_h_pixel             ;  //水平总像素大小 
wire  [12:0] total_v_pixel             ;  //垂直总像素大小
wire  [2:0]  tmds_data_p               ;  //TMDS 数据通道
wire  [2:0]  tmds_data_n               ;

//   main code

assign  clk_50m = sys_clk;


//待时钟锁定后产生复位结束信号
assign  rst_n = sys_rst_n & locked;

assign  locked =  lock3;

//系统初始化完成：DDR3初始化完成
assign  sys_init_done = init_calib_complete;


//cmos 时钟选择信号, 1:使用摄像头自带的晶振
assign  cam_sgm_ctrl_1 = 1'b1;
assign  cam_sgm_ctrl_2 = 1'b1;
assign  cam_sgm_ctrl_3 = 1'b1;
assign  cam_sgm_ctrl_4 = 1'b1;


Gowin_rPLL_325 u_Gowin_rPLL_325(
        .clkout(clk_325m), //output clkout
        .lock(lock3), //output lock
        .reset(~sys_rst_n), //input reset
        .clkin(sys_clk) //input clkin
    );

 CLKDIV u_clkdiv
    (.RESETN(rst_n)
    ,.HCLKIN(clk_325m) // 325 = 65 * 5
    ,.CLKOUT(clk_65m)  // 与clk_325m同相位
    ,.CALIB (1'b1)
    );
    defparam u_clkdiv.DIV_MODE="5";
    defparam u_clkdiv.GSREN="false";
   

ov7725_dri u_ov7725_dri_1(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk_1),
    .cam_vsync         (cam_vsync_1),
    .cam_href          (cam_href_1 ),
    .cam_data          (cam_data_1 ),
    .cam_rst_n         (cam_rst_n_1),
    .cam_pwdn          (cam_pwdn_1),
    .cam_scl           (cam_scl_1  ),
    .cam_sda           (cam_sda_1  ),
    
    .capture_start     (init_calib_complete),
    .cam_init_done     (cam_init_done_1),

    .cmos_frame_vsync  (cmos_frame_vsync_1),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid_1),
    .cmos_frame_data   (wr_data_1)
    );   
    
ov7725_dri u_ov7725_dri_2(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk_2 ),
    .cam_vsync         (cam_vsync_2),
    .cam_href          (cam_href_2 ),
    .cam_data          (cam_data_2),
    .cam_rst_n         (cam_rst_n_2),
    .cam_pwdn          (cam_pwdn_2 ),
    .cam_scl           (cam_scl_2  ),
    .cam_sda           (cam_sda_2 ),
    
    .capture_start     (init_calib_complete),
    .cam_init_done     (cam_init_done_2),

    .cmos_frame_vsync  (cmos_frame_vsync_2),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid_2),
    .cmos_frame_data   (wr_data_2)
    );

ov7725_dri u_ov7725_dri_3(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk_3 ),
    .cam_vsync         (cam_vsync_3),
    .cam_href          (cam_href_3 ),
    .cam_data          (cam_data_3),
    .cam_rst_n         (cam_rst_n_3),
    .cam_pwdn          (cam_pwdn_3 ),
    .cam_scl           (cam_scl_3  ),
    .cam_sda           (cam_sda_3 ),
    
    .capture_start     (init_calib_complete),
    .cam_init_done     (cam_init_done_3),

    .cmos_frame_vsync  (cmos_frame_vsync_3),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid_3),
    .cmos_frame_data   (wr_data_3)
    );

ov7725_dri u_ov7725_dri_4(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk_4 ),
    .cam_vsync         (cam_vsync_4),
    .cam_href          (cam_href_4 ),
    .cam_data          (cam_data_4),
    .cam_rst_n         (cam_rst_n_4),
    .cam_pwdn          (cam_pwdn_4 ),
    .cam_scl           (cam_scl_4  ),
    .cam_sda           (cam_sda_4 ),
    
    .capture_start     (init_calib_complete),
    .cam_init_done     (cam_init_done_4),

    .cmos_frame_vsync  (cmos_frame_vsync_4),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid_4),
    .cmos_frame_data   (wr_data_4)
    );          
    
ddr3_top u_ddr3_top (
    .clk_50m               (clk_50m),                   //系统时钟
    .sys_rst_n             (rst_n),                     //复位,低有效
    .sys_init_done         (sys_init_done),             //系统初始化完成
    .init_calib_complete   (init_calib_complete),       //ddr3初始化完成信号    
    //ddr3接口信号                                      
    .app_addr_rd_min       (28'd0),                     //读DDR3的起始地址
    .app_addr_rd_max       (V_CMOS_DISP*H_CMOS_DISP),   //读DDR3的结束地址
    .rd_bust_len           (H_CMOS_DISP[10:3]),         //从DDR3中读数据时的突发长度
    .app_addr_wr_min       (28'd0),                     //写DDR3的起始地址
    .app_addr_wr_max       (V_CMOS_DISP*H_CMOS_DISP),   //写DDR3的结束地址
    .wr_bust_len           (H_CMOS_DISP[10:3]),         //从DDR3中读数据时的突发长度
    // DDR3 IO接口                
    .ddr3_dq               (ddr3_dq),                   //DDR3 数据
    .ddr3_dqs_n            (ddr3_dqs_n),                //DDR3 dqs负
    .ddr3_dqs_p            (ddr3_dqs_p),                //DDR3 dqs正  
    .ddr3_addr             (ddr3_addr),                 //DDR3 地址   
    .ddr3_ba               (ddr3_ba),                   //DDR3 banck 选择
    .ddr3_ras_n            (ddr3_ras_n),                //DDR3 行选择
    .ddr3_cas_n            (ddr3_cas_n),                //DDR3 列选择
    .ddr3_we_n             (ddr3_we_n),                 //DDR3 读写选择
    .ddr3_reset_n          (ddr3_reset_n),              //DDR3 复位
    .ddr3_ck_p             (ddr3_ck_p),                 //DDR3 时钟正
    .ddr3_ck_n             (ddr3_ck_n),                 //DDR3 时钟负  
    .ddr3_cke              (ddr3_cke),                  //DDR3 时钟使能
    .ddr3_cs_n             (ddr3_cs_n),                 //DDR3 片选
    .ddr3_dm               (ddr3_dm),                   //DDR3_dm
    .ddr3_odt              (ddr3_odt),                  //DDR3_odt
    //用户                                              
    .wr_clk_1              (cam_pclk_1),                //摄像头1时钟
    .wr_load_1             (cmos_frame_vsync_1),        //摄像头1场信号    
	.datain_valid_1        (cmos_frame_valid_1),        //数据1有效使能信号
    .datain_1              (wr_data_1),                 //有效数据1 

    .wr_clk_2              (cam_pclk_2),                //摄像头2时钟
    .wr_load_2             (cmos_frame_vsync_2),        //摄像头2场信号    
	.datain_valid_2        (cmos_frame_valid_2),        //数据有效使能信号
    .datain_2              (wr_data_2),                 //有效数据    

    .wr_clk_3              (cam_pclk_3),                //摄像头1时钟
    .wr_load_3             (cmos_frame_vsync_3),        //摄像头1场信号    
	.datain_valid_3        (cmos_frame_valid_3),        //数据1有效使能信号
    .datain_3              (wr_data_3),                 //有效数据1 

    .wr_clk_4              (cam_pclk_4),                //摄像头2时钟
    .wr_load_4             (cmos_frame_vsync_4),        //摄像头2场信号    
	.datain_valid_4        (cmos_frame_valid_4),        //数据有效使能信号
    .datain_4              (wr_data_4),                 //有效数据 

    .h_disp                (11'd1280),    
    .v_disp                (11'd960),

    .rd_clk                (clk_65m),                   //rfifo的读时钟 
    .rd_load               (rd_vsync),                  //lcd场信号    
    .dataout               (rd_data),                   //rfifo输出数据
    .rdata_req             (rdata_req)                  //请求数据输入   
     );                



//HDMI驱动显示模块    
hdmi_top u_hdmi_top(
    .pixel_clk            (clk_65m),
    .pixel_clk_5x         (clk_325m),    
    .sys_rst_n            (sys_init_done & rst_n),
    //hdmi接口
    .tmds_clk_p           (tmds_clk_p   ),    // TMDS 时钟通道
    .tmds_clk_n           (tmds_clk_n   ),
    .tmds_data_p          (tmds_data_p  ),    // TMDS 数据通道
    .tmds_data_n          (tmds_data_n  ),
    //用户接口 
    .video_vs             (rd_vsync     ),    //HDMI场信号  
    .h_disp               (h_disp),           //HDMI屏水平分辨率
    .v_disp               (v_disp),           //HDMI屏垂直分辨率         
    .data_in              (rd_data),          //CMOS传感器像素点数据 
    .data_req             (rdata_req)         //请求数据输入   
);  
    
endmodule