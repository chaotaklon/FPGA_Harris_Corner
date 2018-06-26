----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: top_level - Behavioral 
-- Description: Top level module of the Zedboard OV7670 design
--http://hamsterworks.co.nz/mediawiki/index.php/Zedboard_OV7670
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity top_level is
    Port ( clk100          : in  STD_LOGIC;
           btnl            : in  STD_LOGIC;
           btnc            : in  STD_LOGIC;
           btnr            : in  STD_LOGIC;
           config_finished : out STD_LOGIC;
           
           vga_hsync : out  STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_r     : out  STD_LOGIC_vector(3 downto 0);
           vga_g     : out  STD_LOGIC_vector(3 downto 0);
           vga_b     : out  STD_LOGIC_vector(3 downto 0);
           
           ov7670_pclk  : in  STD_LOGIC;
           ov7670_xclk  : out STD_LOGIC;
           ov7670_vsync : in  STD_LOGIC;
           ov7670_href  : in  STD_LOGIC;
           ov7670_data  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc  : out STD_LOGIC;
           ov7670_siod  : inout STD_LOGIC;
           ov7670_pwdn  : out STD_LOGIC;
           ov7670_reset : out STD_LOGIC
           );
end top_level;

architecture Behavioral of top_level is

	COMPONENT VGA
	PORT(
		CLK25 : IN std_logic;    
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		Hsync : OUT std_logic;
		Vsync : OUT std_logic;
		Nblank : OUT std_logic;      
		clkout : OUT std_logic;
		activeArea : OUT std_logic;
		Nsync : OUT std_logic
		);
	END COMPONENT;

	COMPONENT ov7670_controller
	PORT(
		clk : IN std_logic;
		resend : IN std_logic;    
		siod : INOUT std_logic;      
		config_finished : OUT std_logic;
		sioc : OUT std_logic;
		reset : OUT std_logic;
		pwdn : OUT std_logic;
		xclk : OUT std_logic
		);
	END COMPONENT;

	COMPONENT debounce
	PORT(
		clk : IN std_logic;
		i : IN std_logic;          
		o : OUT std_logic
		);
	END COMPONENT;

	COMPONENT frame_buffer
	PORT(
		data : IN std_logic_vector(7 downto 0);
		rdaddress : IN std_logic_vector(18 downto 0);
		rdclock : IN std_logic;
		wraddress : IN std_logic_vector(18 downto 0);
		wrclock : IN std_logic;
		wren : IN std_logic;          
		q : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
-----
	COMPONENT cv_top
	PORT(
		pclk : IN std_logic;
		addr_in : IN std_logic_vector(18 downto 0);
		data_in : IN std_logic_vector(15 downto 0);
		en_in : IN std_logic;          
		addr_out : OUT std_logic_vector(18 downto 0);
		data_out : OUT std_logic_vector(7 downto 0);
		en_out : OUT std_logic
		);
	END COMPONENT;
-----
	COMPONENT ov7670_capture
	PORT(
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		pclk : IN std_logic;
		vsync : IN std_logic;
		href : IN std_logic;
		d : IN std_logic_vector(7 downto 0);          
		addr : OUT std_logic_vector(18 downto 0);
		dout : OUT std_logic_vector(15 downto 0);
		we : OUT std_logic
		);
	END COMPONENT;

	COMPONENT RGB
	PORT(
		Din : IN std_logic_vector(7 downto 0);
		Nblank : IN std_logic;          
		R : OUT std_logic_vector(7 downto 0);
		G : OUT std_logic_vector(7 downto 0);
		B : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	component vga_pll_zedboard
	port (
		CLK100       : in  std_logic;
		CLK50_camera : out std_logic;
		CLK25_vga    : out std_logic);
	end component;

	COMPONENT Address_Generator
	PORT(
		CLK25       : IN  std_logic;
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		enable      : IN  std_logic;       
      vsync       : in  STD_LOGIC;
		address     : OUT std_logic_vector(18 downto 0)
		);
	END COMPONENT;

	
	signal ov7670_pclk_bufg	: std_logic;

   signal clk_camera : std_logic;
   signal clk_vga    : std_logic;
   signal wren       : std_logic;
   signal resend     : std_logic;
   signal nBlank     : std_logic;
   signal vSync      : std_logic;
   signal nSync      : std_logic;
   
   signal wraddress  : std_logic_vector(18 downto 0);
   signal wrdata     : std_logic_vector(15 downto 0);
	
	signal cv_top_wr_addr_out	: std_logic_vector(18 downto 0);
	signal cv_top_wr_data_out	: std_logic_vector(7 downto 0);
	signal cv_top_wr_en_out		: std_logic;
   
   signal rdaddress  : std_logic_vector(18 downto 0);
   signal rddata     : std_logic_vector(7 downto 0);
   signal red,green,blue : std_logic_vector(7 downto 0);
   signal activeArea : std_logic;
   
   signal rez_160x120 : std_logic;
   signal rez_320x240 : std_logic;
begin
   vga_r <= red(7 downto 4);
   vga_g <= green(7 downto 4);
   vga_b <= blue(7 downto 4);
   
   rez_160x120 <= btnl;
   rez_320x240 <= btnr;
	
   -- BUFG: Global Clock Simple Buffer
   --       Artix-7
   -- Xilinx HDL Language Template, version 14.5
	BUFG_inst : BUFG port map (
		O => ov7670_pclk_bufg, -- 1-bit output: Clock output
		I => ov7670_pclk  -- 1-bit input: Clock input
	);

	inst_vga_pll : vga_pll_zedboard port map( 
	  CLK100 => CLK100,
     CLK50_camera => CLK_camera,
     CLK25_vga => CLK_vga
	);

   vga_vsync <= vsync;
   
	Inst_VGA: VGA PORT MAP(
		CLK25      => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		clkout     => open,
		Hsync      => vga_hsync,
		Vsync      => vsync,
		Nblank     => nBlank,
		Nsync      => nsync,
      activeArea => activeArea
	);

	Inst_debounce: debounce PORT MAP(
		clk => clk_vga,
		i   => btnc,
		o   => resend
	);

	Inst_ov7670_controller: ov7670_controller PORT MAP(
		clk             => clk_camera,
		resend          => resend,
		config_finished => config_finished,
		sioc            => ov7670_sioc,
		siod            => ov7670_siod,
		reset           => ov7670_reset,
		pwdn            => ov7670_pwdn,
		xclk            => ov7670_xclk
	);

	Inst_frame_buffer: frame_buffer PORT MAP(
		rdaddress => rdaddress,
		rdclock   => clk_vga,
		q         => rddata,
      
		wrclock   => ov7670_pclk_bufg,
		wraddress => cv_top_wr_addr_out,
		data      => cv_top_wr_data_out,
		wren      => cv_top_wr_en_out
	);
------------
	Inst_cv_top: cv_top PORT MAP(
		pclk => ov7670_pclk_bufg,
		addr_in => wraddress,
		data_in => wrdata,
		en_in => wren,
		addr_out => cv_top_wr_addr_out,
		data_out => cv_top_wr_data_out,
		en_out => cv_top_wr_en_out
	);
------------
	Inst_ov7670_capture: ov7670_capture PORT MAP(
		pclk  => ov7670_pclk_bufg,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		vsync => ov7670_vsync,
		href  => ov7670_href,
		d     => ov7670_data,
		addr  => wraddress,
		dout  => wrdata,
		we    => wren
	);

	Inst_RGB: RGB PORT MAP(
		Din => rddata,
		Nblank => activeArea,
		R => red,
		G => green,
		B => blue
	);

	Inst_Address_Generator: Address_Generator PORT MAP(
		CLK25 => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		enable => activeArea,
      vsync  => vsync,
		address => rdaddress
	);

end Behavioral;

