entity overflow is
    generic(
        max: integer
    );
    -- abstract begin
    -- constraint max>1;
    -- abstract end
    port(
        reset: in std_logic;
        clk: in std_logic
    );
end entity overflow;

architecture behavioral of overflow is
    signal addr: std_logic_vector(32 downto 0);
    -- bad state definition
    signal bad: std_logic;
begin

-- addr
process(reset, clk)
begin
    if (reset = '1') then
        addr <= (others => '0');
    elsif (clk'event and clk = '1') then
        if (addr = max-1) then
            addr <= (others => '0');
        else
            addr <= addr+1;
        end if;
    end if;
end process;

-- bad
-- process(reset, clk)
-- begin
--     if (reset = '1') then
--         bad <= '0';
--     elsif (clk'event and clk = '1') then
--         bad <= addr = max;
--     end if;
-- end process;
bad <= not(reset or (addr/=max));

end architecture behavioral;
