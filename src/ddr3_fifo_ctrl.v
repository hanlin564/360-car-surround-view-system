`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input           rst_n            ,  //复位信号
    input           wr_clk           ,  //wfifo时钟
    input           rd_clk           ,  //rfifo时钟
    input           clk_100          ,  //用户时钟
    input           datain_valid     ,  //数据有效使能信号
    input  [15:0]   datain           ,  //有效数据
    input  [127:0]  rfifo_din        ,  //用户读数据
    input           rdata_req        ,  //请求像素点颜色数据输入 
    input           rfifo_wren       ,  //从ddr3读出数据的有效使能
    input           wfifo_rden       ,  //wfifo读使能
    input           rd_load          ,  //输出源场信号
    input           wr_load          ,  //输入源场信号          

    output [127:0]  wfifo_dout       ,  //用户写数据
    output [10:0]   wfifo_rcount     ,  //rfifo剩余数据计数
    output [10:0]   rfifo_wcount     ,  //wfifo写进数据计数
    output [15:0]   pic_data            //有效数据     	
    );
           
//reg define
reg  [127:0] datain_t          ;  //由16bit输入源数据移位拼接得到
reg  [7:0]   cam_data_d0       ; 
reg  [4:0]   i_d0              ;
reg  [15:0]  rd_load_d         ;  //由输出源场信号移位拼接得到           
reg  [6:0]   byte_cnt          ;  //写数据移位计数器
reg  [127:0] data              ;  //rfifo输出数据打拍得到
reg  [15:0]  pic_data          ;  //有效数据 
reg  [4:0]   i                 ;  //读数据移位计数器
reg  [15:0]  wr_load_d         ;  //由输入源场信号移位拼接得到 
reg  [3:0]   cmos_ps_cnt       ;  //等待帧数稳定计数器
reg          cam_href_d0       ;
reg          cam_href_d1       ;
reg          wr_load_d0        ;
reg          rd_load_d0        ;
reg          rdfifo_rst_h      ;  //rfifo复位信号，高有效
reg          wr_load_d1        ;
reg          wfifo_rst_h       ;  //wfifo复位信号，高有效
reg          wfifo_wren        ;  //wfifo写使能信号

//wire define 
wire [127:0] rfifo_dout        ;  //rfifo输出数据    
wire [127:0] wfifo_din         ;  //wfifo写数据
wire [15:0]  dataout[0:15]     ;  //定义输出数据的二维数组
wire         rfifo_rden        ;  //rfifo的读使能


//main code

//rfifo输出的数据存到二维数组
assign dataout[0] = data[127:112];
assign dataout[1] = data[111:96];
assign dataout[2] = data[95:80];
assign dataout[3] = data[79:64];
assign dataout[4] = data[63:48];
assign dataout[5] = data[47:32];
assign dataout[6] = data[31:16];
assign dataout[7] = data[15:0];

assign wfifo_din = datain_t ;

//移位寄存器计满时，从rfifo读出一个数据
assign rfifo_rden = (rdata_req && (i==7)) ? 1'b1  :  1'b0; 

//16位数据转128位RGB565数据        
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        datain_t <= 0;
        byte_cnt <= 0;
    end
    else if(datain_valid) begin
        if(byte_cnt == 7)begin
            byte_cnt <= 0;
            datain_t <= {datain_t[111:0],datain};
        end
        else begin
            byte_cnt <= byte_cnt + 1;
            datain_t <= {datain_t[111:0],datain};
        end
    end
    else begin
        byte_cnt <= byte_cnt;
        datain_t <= datain_t;
    end    
end 

//wfifo写使能产生
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        wfifo_wren <= 0;
    else if(wfifo_wren == 1)
        wfifo_wren <= 0;
    else if(byte_cnt == 7 && datain_valid )  //输入源数据传输8次，写使能拉高一次
        wfifo_wren <= 1;
    else 
        wfifo_wren <= 0;
 end
     
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n)
        data <= 127'b0;
    else 
        data <= rfifo_dout; 
end     

//对rfifo出来的128bit数据拆解成16个16bit数据
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        pic_data <= 16'b0;
        i <=0;
        i_d0 <= 0;
    end
    else if(rdata_req) begin
        if(i == 7)begin
            pic_data <= dataout[i_d0];
            i <= 0;
            i_d0 <= i;
        end
        else begin
            pic_data <= dataout[i_d0];
            i <= i + 1;
            i_d0 <= i;
        end
    end 
    else begin
        pic_data <= pic_data;
        i <=0;
        i_d0 <= 0;
    end
end  

always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        rd_load_d0 <= 1'b0;
    else
        rd_load_d0 <= rd_load;      
end 

//对输出源场信号进行移位寄存
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        rd_load_d <= 1'b0;
    else
        rd_load_d <= {rd_load_d[14:0],rd_load_d0};       
end 

//产生一段复位电平，满足fifo复位时序  
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        rdfifo_rst_h <= 1'b0;
    else if(rd_load_d[0] && !rd_load_d[14])
        rdfifo_rst_h <= 1'b1;   
    else
        rdfifo_rst_h <= 1'b0;              
end  

//对输入源场信号进行移位寄存
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)begin
        wr_load_d0 <= 1'b0;
        wr_load_d  <= 16'b0;        
    end     
    else begin
        wr_load_d0 <= wr_load;
        wr_load_d <= {wr_load_d[14:0],wr_load_d0};      
    end                 
end  

//产生一段复位电平，满足fifo复位时序 
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
      wfifo_rst_h <= 1'b0;          
    else if(wr_load_d[0] && !wr_load_d[15])
      wfifo_rst_h <= 1'b1;       
    else
      wfifo_rst_h <= 1'b0;                      
end   
//gowin IP
fifo_top_rd u_fifo_rd(
		.Data(rfifo_din), //input [127:0] Data
		.Reset(~rst_n|rdfifo_rst_h), //input Reset
		.WrClk(clk_100), //input WrClk
		.RdClk(rd_clk), //input RdClk
		.WrEn(rfifo_wren), //input WrEn
		.RdEn(rfifo_rden), //input RdEn
		.Wnum(rfifo_wcount), //output [9:0] Wnum
		.Rnum(), //output [9:0] Rnum
		.Q(rfifo_dout), //output [127:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);
 fifo_top_wr u_fifo_wr(
		.Data(wfifo_din), //input [127:0] Data
		.Reset(~rst_n|wfifo_rst_h), //input Reset
		.WrClk(wr_clk), //input WrClk
		.RdClk(clk_100), //input RdClk
		.WrEn(wfifo_wren), //input WrEn
		.RdEn(wfifo_rden), //input RdEn
		.Wnum(), //output [9:0] Wnum
		.Rnum(wfifo_rcount), //output [9:0] Rnum
		.Q(wfifo_dout), //output [127:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);
/*
rd_fifo u_rd_fifo (
  .rst               (~rst_n|rdfifo_rst_h),                    
  .wr_clk            (clk_100),   
  .rd_clk            (rd_clk),    
  .din               (rfifo_din), 
  .wr_en             (rfifo_wren),
  .rd_en             (rfifo_rden),
  .dout              (rfifo_dout),
  .full              (),          
  .empty             (),          
  .rd_data_count     (),  
  .wr_data_count     (rfifo_wcount),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()      
);

wr_fifo u_wr_fifo (
  .rst               (~rst_n|wfifo_rst_h),
  .wr_clk            (wr_clk),            
  .rd_clk            (clk_100),           
  .din               (wfifo_din),         
  .wr_en             (wfifo_wren),        
  .rd_en             (wfifo_rden),        
  .dout              (wfifo_dout ),       
  .full              (),                  
  .empty             (),                  
  .rd_data_count     (wfifo_rcount),  
  .wr_data_count     (),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()    
);*/

endmodule 

