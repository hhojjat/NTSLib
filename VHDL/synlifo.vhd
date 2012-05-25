--
-- synlifo: Synchronous LIFO
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
entity test is
    generic( MAX: integer );    -- should be greater then 1
    -- abstract begin
    -- constraint max>1;
    -- abstract end
    port(
        RESET: in std_logic;
        CLK: in std_logic;
        WR: in std_logic;
        RD: in std_logic;
        FULL: out std_logic;    -- ==1 if addr==max-1 (ales: from specs)
        EMPTY: out std_logic    -- ==1 if addr==0 (ales: from specs)
    );
end entity test;

architecture behavioral of test is

    signal addr: std_logic_vector(32 downto 0);
    signal read_allow: std_logic;
    signal write_allow: std_logic;
    -- bad state specification
    signal bad: std_logic;
    signal p_addr: std_logic_vector(32 downto 0);

begin

read_allow <= (not empty and rd and not wr);
write_allow <= (not full and wr and not rd);

-- addr
process(reset, clk)
begin
    if (reset = '1') then
        addr <= (others => '0');
    elsif (clk'event and clk = '1') then
        if (read_allow = '1') then
            addr <= addr-1;
        elsif (write_allow = '1') then
            addr <= addr+1;
        end if;
    end if;
end process;

-- empty
process(reset, clk)
begin
    if (reset = '1') then
        empty <= '1';
    elsif (clk'event and clk = '1') then
        empty <= addr = 0;
    end if;
end process;

-- full
process(reset, clk)
begin
    if (reset = '1') then
        full <= '0';
    elsif (clk'event and clk = '1') then
        full <= addr = max-1;
    end if;
end process;

--------------------------------------------------------------------------
-- bad
-- property: Full and Empty is set appropriatelly.

-- next(p_addr) = addr
process(reset, clk)
begin
    if (reset = '1') then
        p_addr <= (others => '0');
    elsif (clk'event and clk = '1') then
        p_addr <= addr;
    end if;
end process;

-- ARMC output plugin do not understand a non-CNF of expression:
-- bad <= not((reset and empty and (addr=0)) or
--            (not reset and empty and (addr=0)) or
--            (not reset and full and (addr=(max-1))) or
--            (not reset and not empty and (addr>0)) or
--            (not reset and not full and (addr<(max-1))));
-- This form is acceptable:
bad <= not(reset and empty and (p_addr=0)) and
       not(not reset and empty and (p_addr=0)) and
       not(not reset and full and (p_addr=(max-1))) and
       not(not reset and not empty and (p_addr>0)) and
       not(not reset and not full and (p_addr<(max-1)));

end architecture behavioral;
