module  hdmi_top(
    input           pixel_clk,
    input           pixel_clk_5x,    
    input           sys_rst_n,
   //hdmi接口       
    output          tmds_clk_p,      // TMDS 时钟通道
    output          tmds_clk_n,
    output  [2:0]   tmds_data_p,     // TMDS 数据通道
    output  [2:0]   tmds_data_n,
   //用户接口 
    output          video_vs,        //HDMI场信号      
    output  [10:0]  h_disp,          //HDMI屏水平分辨率
    output  [10:0]  v_disp,          //HDMI屏垂直分辨率         
    input   [15:0]  data_in,         //数据输入
    output          data_req         //请求数据输入   
);

//wire define
wire          pixel_clk;
wire          pixel_clk_5x;
wire          clk_locked;
wire  [2:0]   tmds_data_p;   // TMDS 数据通道
wire  [2:0]   tmds_data_n;

wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;
wire  [10:0]  h_disp;
wire  [10:0]  v_disp;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;
wire  [15:0]  video_rgb_565;

//main code


//将摄像头16bit数据转换为24bit的hdmi数据
assign video_rgb = {video_rgb_565[15:11],3'b000,video_rgb_565[10:5],2'b00,
                    video_rgb_565[4:0],3'b000};  

//例化视频显示驱动模块
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb_565),
   
    .data_req       (data_req),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (data_in)
    );




 //gowin HDMI_TX IP
DVI_TX_Top u_DVI_TX_Top(
  .I_rst_n(sys_rst_n),
  .I_serial_clk(pixel_clk_5x),
  .I_rgb_clk(pixel_clk),
  .I_rgb_vs(video_vs),
  .I_rgb_hs(video_hs),
  .I_rgb_de(video_de),
  .I_rgb_r(video_rgb[23:16]), 
  .I_rgb_g(video_rgb[15:8]), 
  .I_rgb_b(video_rgb[7:0]),
  .O_tmds_clk_p(tmds_clk_p),
  .O_tmds_clk_n(tmds_clk_n),
  .O_tmds_data_p(tmds_data_p),
  .O_tmds_data_n(tmds_data_n)
)
;    

endmodule 