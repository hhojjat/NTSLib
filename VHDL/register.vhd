entity flipflop is
    port(
        reset: in std_logic;
        data: in std_logic_vector(32 downto 0);
        clk: in std_logic;
        en: in std_logic;
        q: out std_logic_vector(32 downto 0)
    );
end entity flipflop;

architecture ff of flipflop is
    -- bad state definition
    signal bad: std_logic;
begin

process(reset, clk, en)
begin
    if (reset = '1') then
        q <= (others => '0');
    elsif (clk'event and clk = '1') then
        if (en = '1') then
            q <= data;
        end if;
    end if;
end process;

-- 1. Reset
bad <= reset and q/=0;
-- 2. Data transfer (unsupported due to clk'event expression)
-- bad <= not reset and (clk'event and clk='1') and en and (q/=data);

-- now for ARMC that has no random values:
process(reset)
begin
    if (reset = '1') then
        data <= (others => '0');
    end if;
end process;


end architecture behavioral;
