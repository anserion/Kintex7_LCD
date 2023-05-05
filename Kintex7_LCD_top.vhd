library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Kintex7_LCD_top is
    Port (
			CLK50_in : in  STD_LOGIC;
         key: in  STD_LOGIC_VECTOR(1 downto 0);
         led: out  STD_LOGIC_VECTOR(1 downto 0);

         OV7670_SIOC  : out   STD_LOGIC;
         OV7670_SIOD  : inout STD_LOGIC;
         OV7670_RESET : out   STD_LOGIC;
         OV7670_PWDN  : out   STD_LOGIC;
         OV7670_VSYNC : in    STD_LOGIC;
         OV7670_HREF  : in    STD_LOGIC;
         OV7670_PCLK  : in    STD_LOGIC;
         OV7670_XCLK  : out   STD_LOGIC;
         OV7670_D     : in    STD_LOGIC_VECTOR(7 downto 0);

			AN430_dclk : out  STD_LOGIC;
			AN430_red  : out  STD_LOGIC_VECTOR (7 downto 0);
         AN430_green: out  STD_LOGIC_VECTOR (7 downto 0);
         AN430_blue : out  STD_LOGIC_VECTOR (7 downto 0);
         AN430_de   : out  STD_LOGIC
		);
end Kintex7_LCD_top;

architecture XC7K325T of Kintex7_LCD_top is
component clk_core is
	port (
	CLK50_IN: in std_logic;
	CLK100: out std_logic;
	CLK25: out std_logic;
	CLK8: out std_logic
	);
end component;
signal clk100,clk25,clk8:std_logic;

component LCD_AN430 is
    Port ( lcd_clk   : in std_logic;
           lcd_r_out : out  STD_LOGIC_VECTOR (7 downto 0);
           lcd_g_out : out  STD_LOGIC_VECTOR (7 downto 0);
           lcd_b_out : out  STD_LOGIC_VECTOR (7 downto 0);
           lcd_de    : out  STD_LOGIC;
			  clk_wr: in std_logic;
           x : in  STD_LOGIC_VECTOR (9 downto 0);
           y : in  STD_LOGIC_VECTOR (9 downto 0);
			  pixel : in std_logic_vector(7 downto 0)
    );
end component;
signal lcd_clk: std_logic;
signal lcd_de: std_logic:='0';
signal lcd_pixel: STD_LOGIC_VECTOR (7 downto 0):=(others=>'0');
signal lcd_x: STD_LOGIC_VECTOR (9 downto 0):=(others=>'0');
signal lcd_y: STD_LOGIC_VECTOR (9 downto 0):=(others=>'0');
signal lcd_flag: std_logic:='0';
	
component CAM_OV7670 is
    Port (
      clk   : in std_logic;
      vsync : in std_logic;
		href  : in std_logic;
		din   : in std_logic_vector(7 downto 0);
      x : out std_logic_vector(9 downto 0);
      y : out std_logic_vector(9 downto 0);
      pixel : out std_logic_vector(7 downto 0);
      ready : out std_logic
		);
end component;
signal cam_ready    : std_logic;
signal cam_clk      : std_logic;
signal cam_pixel    : std_logic_vector(7 downto 0):=(others=>'0');
signal cam_x        : std_logic_vector(9 downto 0):=(others=>'0');
signal cam_y        : std_logic_vector(9 downto 0):=(others=>'0');
	
begin
led<=key;

clk_chip : clk_core port map (CLK50_in,CLK100,CLK25,CLK8);
lcd_clk<=clk8;
cam_clk<=clk25;
  
AN430_dclk<=not(lcd_clk);
AN430_de<=lcd_de;
AN430_lcd: LCD_AN430 port map (
		lcd_clk,AN430_red,AN430_green,AN430_blue,lcd_de,
      cam_clk,lcd_x,lcd_y,lcd_pixel);

--minimal OV7670 grayscale mode
OV7670_PWDN  <= '0'; --0 - power on
OV7670_RESET <= '1'; --0 - activate reset
OV7670_XCLK  <= cam_clk;
OV7670_siod  <= 'Z';
OV7670_sioc  <= '0';
   
OV7670_cam: CAM_OV7670 PORT MAP(
		clk   => OV7670_PCLK,
		vsync => OV7670_VSYNC,
		href  => OV7670_HREF,
		din   => OV7670_D,
      x =>cam_x,
      y =>cam_y,
      pixel =>cam_pixel,
      ready =>cam_ready
      );
      
lcd_flag<='1' when (cam_x>=80)and(cam_x<560)and(cam_y>=104)and(cam_y<376) else '0';      
lcd_x<=cam_x-conv_std_logic_vector(80,10) when lcd_flag='1' else (others=>'0');
lcd_y<=cam_y-conv_std_logic_vector(104,10) when lcd_flag='1' else (others=>'0');
lcd_pixel<=cam_pixel when lcd_flag='1' else (others=>'0');
end;
