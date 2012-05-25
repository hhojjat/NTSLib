--
-- asfifo: Asynchronous FIFO from LUTs
-- Copyright (C) 2003 CESNET
-- Author(s): Martinek Tomas <martinek@liberouter.org>
--            Martin Mikusek <martin.mikusek@liberouter.org>
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the OpenIPCore Hardware General Public
-- License as published by the OpenIPCore Organization; either version
-- 0.20-15092000 of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- OpenIPCore Hardware General Public License for more details.
--
-- You should have received a copy of the OpenIPCore Hardware Public
-- License along with this program; if not, download it from
-- OpenCores.org (http://www.opencores.org/OIPC/OHGPL.shtml).
--
-- $Id: asfifo.vhd,v 1.6 2005/10/19 13:59:31 martinek Exp $
--
-- TODO:
--
--
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

-- library containing log2 function
use work.math_pack.all;

-- counter package
use work.cnt_types.all;

-- auxilarity function needed to compute address width
use WORK.distmem_func.all;

-- pragma translate_off
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
-- pragma translate_on
-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity asfifo is
   generic(
      -- Data Width
      DATA_WIDTH  : integer;
      -- Item in memory needed, one item size is DATA_WIDTH
      ITEMS : integer;
      -- Distributed Ram Type(capacity) only 16, 32, 64 bits
      DISTMEM_TYPE : integer := 16;

      -- Width of status information of fifo fullness
      -- Note: 2**STATUS_WIDTH MUST BE!! less or equal
      --       than ITEMS
      STATUS_WIDTH : integer
   );
   -- abstract begin
   -- constraint items>4;
   -- abstract end
   port(
      RESET    : in  std_logic;

      -- Write interface
      CLK_WR   : in  std_logic;
      DI       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      WR       : in  std_logic;
      FULL     : out std_logic;
      STATUS      : out std_logic_vector(STATUS_WIDTH-1 downto 0);

      -- Read interface
      CLK_RD   : in  std_logic;
      DO       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      RD       : in  std_logic;
      EMPTY    : out std_logic
   );
end entity asfifo;

-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of asfifo is

   -- Number of address bits
   -- abstract begin
   constant FADDR       : integer := LOG2(ITEMS)-1;
   -- constant FADDR : integer := ITEMS;
   -- abstract end

   -- FIFO part signals
   signal cnt_read_addr    : std_logic_vector(FADDR downto 0);
   signal read_addrgray    : std_logic_vector(FADDR downto 0);
   signal read_nextgray    : std_logic_vector(FADDR downto 0);
   signal read_lastgray    : std_logic_vector(FADDR downto 0);

   signal cnt_write_addr   : std_logic_vector(FADDR downto 0);
   signal write_addrgray   : std_logic_vector(FADDR downto 0);
   signal write_nextgray   : std_logic_vector(FADDR downto 0);

   signal reg_status         : std_logic_vector(FADDR downto 0);
   signal read_truegray      : std_logic_vector(FADDR downto 0);
   signal reg_read_truegray  : std_logic_vector(FADDR downto 0);
   signal read_bin           : std_logic_vector(FADDR downto 0);
   signal reg_cnt_write_addr : std_logic_vector(FADDR downto 0);

   signal read_allow       : std_logic;
   signal write_allow      : std_logic;
   signal empty_allow      : std_logic;
   signal full_allow       : std_logic;

   -- abstract begin
   -- signal ecomp : std_logic;
   -- signal fcomp : std_logic;
   signal ecomp            : std_logic_vector(FADDR downto 0);
   signal fcomp            : std_logic_vector(FADDR downto 0);
   signal emuxcyo          : std_logic_vector(FADDR+1 downto 0);
   signal fmuxcyo          : std_logic_vector(FADDR+1 downto 0);
   -- abstract end
   signal emptyg           : std_logic;
   signal fullg            : std_logic;
   signal regasync_full    : std_logic;
--    signal reg_full_fall    : std_logic;
   signal regasync_empty   : std_logic;
--    signal reg_empty_fall   : std_logic;

   signal gnd              : std_logic;
   signal pwr              : std_logic;

   signal bad : std_logic;
   signal cnt : std_logic_vector(1 downto 0);

component MUXCY_L
   port (
      DI:  in std_logic;
      CI:  in std_logic;
      S:   in std_logic;
      LO: out std_logic);
end component;

begin
-- ------------------------------------------------------------------------
--                       Memory Instantion
-- ------------------------------------------------------------------------
gnd      <= '0';
pwr      <= '1';

MEM_U : entity work.dp_distmem
--MEM_U : entity dp_distmem
generic map(
   DATA_WIDTH   => DATA_WIDTH,
   ITEMS        => ITEMS,
   DISTMEM_TYPE => DISTMEM_TYPE
)
port map(
   RESET      => RESET,
   -- Write port
   WCLK       => CLK_WR,
   ADDRA      => cnt_write_addr,
   DI         => DI,
   WE         => write_allow,
   DOA        => open,

      -- Read port
   ADDRB      => cnt_read_addr,
   DOB        => DO
);

-- ------------------------------------------------------------------------
--                       FIFO Control Part
-- ------------------------------------------------------------------------
--  allow flags generation

read_allow <= (RD and not regasync_empty);
write_allow <= (WR and not regasync_full);

full_allow <= (regasync_full or WR);
empty_allow <= (regasync_empty or RD);

---------------------------------------------------------------
--  empty and full flag generation

-- falling edge
-- process (CLK_RD, RESET)
-- begin
--    if (RESET = '1') then
--       reg_empty_fall <= '1';
--    elsif (CLK_RD'event and CLK_RD = '0') then
--       if (empty_allow = '1') then
--          reg_empty_fall <= emptyg;
--       end if;
--    end if;
-- end process;

-- rising edge
process (CLK_RD, RESET)
begin
   if (RESET = '1') then
      regasync_empty <= '1';
   elsif (CLK_RD'event and CLK_RD = '1') then
      if (empty_allow = '1') then
--          regasync_empty <= reg_empty_fall;
         regasync_empty <= emptyg;
      end if;
   end if;
end process;

-- falling edge
-- process (CLK_WR, RESET)
-- begin
--    if (RESET = '1') then
--       reg_full_fall <= '1';
--    elsif (CLK_WR'event and CLK_WR = '0') then
--       if (full_allow = '1') then
--          reg_full_fall <= fullg;
--       end if;
--    end if;
-- end process;

-- rising edge
process (CLK_WR, RESET)
begin
   if (RESET = '1') then
      regasync_full <= '0';
   elsif (CLK_WR'event and CLK_WR = '1') then
      if (full_allow = '1') then
--          regasync_full <= reg_full_fall;
         regasync_full <= fullg;
      end if;
   end if;
end process;

----------------------------------------------------------------
--              Read Address Genearation
----------------------------------------------------------------

-- abstract begin
-- process (CLK_RD, RESET)
-- begin
--  if (RESET = '1') then
--      cnt_read_addr <= (others => '0');
--   elsif (CLK_RD'event and CLK_RD = '1') then
--      if (read_allow = '1') then
--          if (cnt_read_addr = ITEMS-1) then
--              cnt_read_addr <= (others => '0');
--          else
--              cnt_read_addr <= cnt_read_addr + 1;
--          end if;
--      end if;
--   end if;
-- end process;

cnt_read_addr_up : entity work.cnt
generic map(
   WIDTH => FADDR+1,
   DIR   => up,
   CLEAR => false
)
port map(
   RESET => RESET,
   CLK   => CLK_RD,
   DO    => cnt_read_addr,
   CLR   => '0',
   CE    => read_allow
);
-- abstract end

process (CLK_RD, RESET)
begin
   if (RESET = '1') then
      -- abstract begin gray
      read_nextgray <= conv_std_logic_vector(2**(FADDR), FADDR+1);
      -- read_nextgray <= ITEMS-1;
      -- abstract end
   elsif (CLK_RD'event and CLK_RD = '1') then
      if (read_allow = '1') then
         -- binary to gray convertor
         -- abstract begin gray
         -- read_nextgray <= cnt_read_addr;
         read_nextgray(FADDR) <= cnt_read_addr(FADDR);
         for i in FADDR-1 downto 0 loop
            read_nextgray(i) <= cnt_read_addr(i+1) xor cnt_read_addr(i);
         end loop;
         -- abstract end
      end if;
   end if;
end process;

process (CLK_RD, RESET)
begin
   if (RESET = '1') then
      -- abstract begin gray
      read_addrgray <= conv_std_logic_vector(2**(FADDR)+1, FADDR+1);
      -- read_addrgray <= ITEMS-2;
      -- abstract end
   elsif (CLK_RD'event and CLK_RD = '1') then
      if (read_allow = '1') then
         read_addrgray <= read_nextgray;
      end if;
   end if;
end process;

proc6: process (CLK_RD, RESET)
begin
   if (RESET = '1') then
      -- abstract begin gray
      read_lastgray <= conv_std_logic_vector(2**(FADDR)+3, FADDR+1);
      -- read_lastgray <= ITEMS-3;
      -- abstract end
   elsif (CLK_RD'event and CLK_RD = '1') then
      if (read_allow = '1') then
         read_lastgray <= read_addrgray;
      end if;
   end if;
end process proc6;

----------------------------------------------------------------
--             Write Address Genearation
----------------------------------------------------------------

-- abstract begin
-- process (CLK_WR, RESET)
-- begin
--   if (RESET = '1') then
--      cnt_write_addr <= (others => '0');
--   elsif (CLK_WR'event and CLK_WR = '1') then
--      if (write_allow = '1') then
-- --         if (cnt_write_addr = ITEMS-1) then
-- --             cnt_write_addr <= (others => '0');
-- --         else
--              cnt_write_addr <= cnt_write_addr + 1;
-- --         end if;
--      end if;
--   end if;
-- end process;

cnt_write_addr_u : entity work.cnt
generic map(
   WIDTH => FADDR+1,
   DIR   => up,
   CLEAR => false
)
port map(
   RESET => RESET,
   CLK   => CLK_WR,
   DO    => cnt_write_addr,
   CLR   => '0',
   CE    => write_allow
);
-- abstract end

process (CLK_WR, RESET)
begin
   if (RESET = '1') then
      -- abstract begin gray
      write_nextgray <= conv_std_logic_vector(2**(FADDR), FADDR+1);
      -- write_nextgray <= ITEMS-1;
      -- abstract end
   elsif (CLK_WR'event and CLK_WR = '1') then
      if (write_allow = '1') then
         -- binary to gray convertor
         -- abstract begin gray
         -- write_nextgray <= cnt_write_addr;
         write_nextgray(FADDR) <= cnt_write_addr(FADDR);
         for i in FADDR-1 downto 0 loop
            write_nextgray(i) <= cnt_write_addr(i+1) xor cnt_write_addr(i);
         end loop;
         -- abstract end
      end if;
   end if;
end process;

process (CLK_WR, RESET)
begin
   if (RESET = '1') then
      -- abstract begin gray
      write_addrgray <= conv_std_logic_vector(2**(FADDR)+1, FADDR+1);
      -- write_addrgray <= ITEMS-2;
      -- abstract end
   elsif (CLK_WR'event and CLK_WR = '1') then
      if (write_allow = '1') then
         write_addrgray <= write_nextgray;
      end if;
   end if;
end process;

----------------------------------------------------------------
--                     Fast carry logic
----------------------------------------------------------------

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- abstract begin
-- ecomp <= ((write_addrgray=read_addrgray) and regasync_empty) or
--          ((write_addrgray=read_nextgray) and not regasync_empty);
ECOMP_GEN : for i in 0 to FADDR generate
   ecomp(i) <= (not (write_addrgray(i) xor read_addrgray(i)) and regasync_empty) or
               (not (write_addrgray(i) xor read_nextgray(i)) and not regasync_empty);
end generate;

emuxcyo(0)  <= pwr;
-- emptyg <= ecomp;
emptyg      <= emuxcyo(FADDR+1);

EMUXCY_GEN : for i in 0 to FADDR generate
   emuxcyX: MUXCY_L
   port map (
      DI => gnd,
      CI => emuxcyo(i),
      S  => ecomp(i),
      LO => emuxcyo(i+1)
   );
end generate;
-- abstract end

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- abstract begin
-- fcomp <= ((read_lastgray=write_addrgray) and regasync_full) or
--          ((read_lastgray=write_nextgray) and not regasync_full);
FCOMP_GEN : for i in 0 to FADDR generate
   fcomp(i) <= (not (read_lastgray(i) xor write_addrgray(i)) and regasync_full) or
               (not (read_lastgray(i) xor write_nextgray(i)) and not regasync_full);
end generate;

fmuxcyo(0)  <= pwr;
-- fullg    <= fcomp;
fullg       <= fmuxcyo(FADDR+1);

FMUXCY_GEN : for i in 0 to FADDR generate
   fmuxcyX: MUXCY_L
   port map (
      DI => gnd,
      CI => fmuxcyo(i),
      S  => fcomp(i),
      LO => fmuxcyo(i+1)
   );
end generate;
-- abstract end

----------------------------------------------------------------
--             Status Genearation
----------------------------------------------------------------
-- graycode read address generation
read_truegray_p: process (CLK_RD, RESET)
begin
   if (RESET='1') then
      read_truegray <= (others=>'0');
   elsif (CLK_RD'event and CLK_RD='1') then
      ----------------------------------------------------
      -- abstract begin
      -- read_truegray <= cnt_read_addr;
      read_truegray(FADDR) <= cnt_read_addr(FADDR);
      read_truegray_gen : for i in FADDR-1 downto 0 loop
         read_truegray(i) <= cnt_read_addr(i+1) xor cnt_read_addr(i);
      end loop;
      -- abstract end
   end if;
end process;

-- synchronization with CLK_WR
reg_read_truegray_p: process (CLK_WR, RESET)
begin
   if (RESET='1') then
      reg_read_truegray <= (others=>'0');
   elsif (CLK_WR'event and CLK_WR='1') then
      reg_read_truegray <= read_truegray;
   end if;
end process;

-- transformation to binary format
-- abstract begin
-- read_bin <= reg_read_truegray;
read_bin(FADDR) <= reg_read_truegray(FADDR);
read_bin_gen : for i in FADDR-1 downto 0 generate
   read_bin(i) <= read_bin(i+1) xor reg_read_truegray(i);
end generate;
-- abstract end

-- registering of cnt_write_addr
reg_cnt_write_addr_p: process (CLK_WR, RESET)
begin
   if (RESET='1') then
      reg_cnt_write_addr <= (others=>'0');
   elsif (CLK_WR'event and CLK_WR='1') then
      reg_cnt_write_addr <= cnt_write_addr;
   end if;
end process;

-- status computing
reg_status_p: process (CLK_WR, RESET)
begin
   if (RESET='1') then
      reg_status <= (others=>'0');
   elsif (CLK_WR'event and CLK_WR='1') then
      if (regasync_full='0') then
-- abstract begin
--        if (reg_cnt_write_addr<read_bin) then
--            reg_status <= (reg_cnt_write_addr+items - read_bin);
--        else
--         reg_status <= (reg_cnt_write_addr - read_bin);
         reg_status <= (reg_cnt_write_addr - read_bin);
--        end if;
-- abstract end
      end if;
   end if;
end process;

----------------------------------------------------------------
--                   Interface Mapping
----------------------------------------------------------------
FULL     <= regasync_full;
EMPTY    <= regasync_empty;
-- abstract begin
-- STATUS <= reg_status;
STATUS <= reg_status(FADDR downto FADDR-STATUS_WIDTH+1); -- we use only few MSB bits
-- abstract end

-- ************************************************************
-- BAD STATE
-- ************************************************************
process(clk_wr,reset)
begin
    if (reset='1') then
      cnt <= (others=>'0');
    elsif (clk_wr'event and clk_wr='1') then
      if (write_allow='1') then
        cnt <= cnt + 1;
      end if;
    end if;
end process;
bad <= not reset and full and cnt<items-3;

end architecture behavioral;
