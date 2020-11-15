 module ov7725_dri (
    input           clk             ,  
    input           rst_n           ,  
     
    input           cam_pclk        ,  
    input           cam_vsync       ,  
    input           cam_href        ,  
    input    [7:0]  cam_data        ,  
    output          cam_rst_n       ,  
    output          cam_pwdn        ,  
    output          cam_scl         ,  
    inout           cam_sda         ,  
    
    input           capture_start   , 
    output          cam_init_done   ,  
    
    //鐢ㄦ埛鎺ュ彛
    output          cmos_frame_vsync,  
    output          cmos_frame_href ,  
    output          cmos_frame_valid,  
    output  [15:0]  cmos_frame_data    
);

//parameter define                     
parameter  SLAVE_ADDR = 7'h21          ;    
parameter  BIT_CTRL   = 1'b0           ;  
parameter  CLK_FREQ   = 26'd50_000_000 ;         
parameter  I2C_FREQ   = 18'd250_000    ;               


//wire difine
wire        i2c_exec       ;       
wire [15:0] i2c_data       ;           
wire        i2c_done       ;         
wire        i2c_dri_clk    ;                    



// main code                      



assign  cam_pwdn  = 1'b0;
assign  cam_rst_n = 1'b1;
    

i2c_ov7725_rgb565_cfg u_i2c_cfg(
    .clk                (i2c_dri_clk),
    .rst_n              (rst_n), 
    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .i2c_done           (i2c_done), 
    .init_done          (cam_init_done) 
    );    


i2c_dri #(
    .SLAVE_ADDR         (SLAVE_ADDR),       
    .CLK_FREQ           (CLK_FREQ  ),              
    .I2C_FREQ           (I2C_FREQ  ) 
    )
u_i2c_dr(
    .clk                (clk),
    .rst_n              (rst_n     ),

    .i2c_exec           (i2c_exec  ),   
    .bit_ctrl           (BIT_CTRL  ),   
    .i2c_rh_wl          (1'b0),           
    .i2c_addr           (i2c_data[15:8]),   
    .i2c_data_w         (i2c_data[7:0]),   
    .i2c_data_r         (),   
    .i2c_done           (i2c_done  ),
    .i2c_ack            (),    
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   

    .dri_clk            (i2c_dri_clk)       
    );


cmos_capture_data u_cmos_capture_data(      
    .rst_n              (rst_n & capture_start),
    
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),         
    
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href ),
    .cmos_frame_valid   (cmos_frame_valid), 
    .cmos_frame_data    (cmos_frame_data )         
    );

endmodule 