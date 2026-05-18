library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_compressor is
    generic(
        CHANNEL_LENGHT  : positive := 24;   -- 24 bits de entrada, vienen del audio I2S por AXIS
        OUTPUT_LENGHT   : positive := 16;   -- 16 bits de salida, dato comprimido
        EXPONENT_LENGTH : POSITIVE := 4     -- cantidad de bits usados para el exponente
    );
    port (
        aclk    : in std_logic;             -- clock del sistema
        aresetn : in std_logic;             -- reset activo en bajo

        -- Interfaz AXI4-Stream de entrada
        -- Aquí entra la muestra de audio original de 24 bits
        s_axis_tvalid : in std_logic;        -- el bloque anterior avisa que el dato de entrada es válido
        s_axis_tdata  : in std_logic_vector(CHANNEL_LENGHT-1 downto 0); -- muestra de audio de entrada
        s_axis_tlast  : in std_logic;        -- marca asociada al dato, se propaga a la salida
        s_axis_tready : out std_logic;       -- este módulo avisa que está listo para recibir

        -- Interfaz AXI4-Stream de salida
        -- Aquí sale la muestra ya comprimida a 16 bits
        m_axis_tvalid : out std_logic;       -- este módulo avisa que la salida es válida
        m_axis_tdata  : out std_logic_vector(OUTPUT_LENGHT-1 downto 0); -- dato comprimido
        m_axis_tlast  : out std_logic;       -- se copia el tlast de entrada
        m_axis_tready : in std_logic         -- el bloque siguiente avisa que puede recibir
    );
end entity float_compressor;

architecture rtl of float_compressor is

    -- El formato de salida es:
    -- [SIGN][EXPONENT][MANTISSA]
    -- Para el caso del lab:
    -- SIGN = 1 bit
    -- EXPONENT = 4 bits
    -- MANTISSA = 11 bits
    constant SIGN_LENGTH     : positive := 1;
    constant MANTISSA_LENGTH : positive := OUTPUT_LENGHT - EXPONENT_LENGTH - SIGN_LENGTH;

    -- Registro interno para manejar el ready de entrada
    signal s_axis_tready_reg : std_logic := '0';

    -- Registros internos para las señales de salida AXIS
    signal m_axis_tvalid_reg : std_logic := '0';
    signal m_axis_tdata_reg  : std_logic_vector(OUTPUT_LENGHT-1 downto 0) := (others => '0');
    signal m_axis_tlast_reg  : std_logic := '0';

    -- FSM sencilla para manejar el protocolo AXIS
    -- WAIT_SAMPLE: estoy listo para recibir una muestra
    -- SEND_SAMPLE: ya comprimí la muestra y la estoy enviando
    type state_type is (WAIT_SAMPLE, SEND_SAMPLE);
    signal state : state_type := WAIT_SAMPLE;

    -- Esta función hace la compresión como la explican las diapositivas:
    -- toma un signed de 24 bits y lo convierte en:
    -- signo + exponente + mantissa
    function compress_sample(
        sample : std_logic_vector(CHANNEL_LENGHT-1 downto 0)
    ) return std_logic_vector is

        -- Versión signed de la entrada, para saber si el número es negativo
        variable sample_signed : signed(CHANNEL_LENGHT-1 downto 0);

        -- Valor absoluto de la muestra. La compresión se hace sobre la magnitud
        variable abs_sample    : unsigned(CHANNEL_LENGHT-1 downto 0);

        -- Campos de la salida comprimida
        variable sign_bit      : std_logic;
        variable exponent      : unsigned(EXPONENT_LENGTH-1 downto 0);
        variable mantissa      : unsigned(MANTISSA_LENGTH-1 downto 0);

        -- Posición del primer '1' empezando desde el MSB
        variable first_one_pos : integer := 0;

        -- Exponente calculado como entero antes de convertirlo a unsigned
        variable exp_int       : integer := 0;

        -- Resultado final de la función
        variable result        : std_logic_vector(OUTPUT_LENGHT-1 downto 0);

    begin

        -- Interpretamos la entrada como signed, porque el audio viene con signo
        sample_signed := signed(sample);

        -- Primero separamos signo y magnitud.
        -- Si es negativo, guardamos sign_bit = 1 y trabajamos con el valor absoluto.
        -- Si es positivo, sign_bit = 0 y la magnitud es el mismo número.
        if sample_signed < 0 then
            sign_bit   := '1';
            abs_sample := unsigned(-sample_signed);
        else
            sign_bit   := '0';
            abs_sample := unsigned(sample_signed);
        end if;

        -- Inicializamos en cero para evitar valores raros
        exponent := (others => '0');
        mantissa := (others => '0');

        -- Caso especial: si la muestra es cero, la salida debe ser todo cero.
        -- No existe "-0", entonces sign_bit queda en 0 porque sample_signed no es menor que 0.
        if abs_sample = 0 then

            exponent := (others => '0');
            mantissa := (others => '0');

        else

            -- Buscamos el primer '1' desde el MSB hacia el LSB.
            -- Con CHANNEL_LENGHT = 24, se revisa desde el bit 23 hasta el bit 0.
            first_one_pos := 0;

            for i in CHANNEL_LENGHT-1 downto 0 loop
                if abs_sample(i) = '1' then
                    first_one_pos := i;
                    exit; -- apenas encontramos el primer 1, salimos del loop
                end if;
            end loop;

            -- Si el primer 1 está dentro de la zona que cabe en la mantissa,
            -- significa que el número es menor que 2^MANTISSA_LENGTH.
            -- En ese caso no hace falta comprimir: exponent = 0 y mantissa = número.
            if first_one_pos < MANTISSA_LENGTH then

                exponent := (others => '0');
                mantissa := resize(abs_sample, MANTISSA_LENGTH);

            else

                -- Si el número no cabe directo en la mantissa, calculamos el exponente.
                -- Fórmula de las diapositivas:
                -- EXP = posición del primer 1 - MANTISSA_LENGTH + 1
                exp_int := first_one_pos - MANTISSA_LENGTH + 1;
                exponent := to_unsigned(exp_int, EXPONENT_LENGTH);

                -- La mantissa son los bits debajo del primer '1'.
                -- La idea es desplazar la magnitud para dejar esos bits en la parte baja
                -- y luego quedarnos solo con MANTISSA_LENGTH bits.
                --
                -- Ejemplo:
                -- si el primer 1 está en bit 20 y la mantissa tiene 11 bits,
                -- queremos tomar aproximadamente los bits 19 downto 9.
                mantissa := resize(shift_right(abs_sample, exp_int - 1), MANTISSA_LENGTH);

            end if;

        end if;

        -- Armamos la salida final:
        -- bit de signo + exponente + mantissa
        result := sign_bit & std_logic_vector(exponent) & std_logic_vector(mantissa);

        return result;

    end function;

begin

    -- Conectamos los registros internos a los puertos de salida
    s_axis_tready <= s_axis_tready_reg;

    m_axis_tvalid <= m_axis_tvalid_reg;
    m_axis_tdata  <= m_axis_tdata_reg;
    m_axis_tlast  <= m_axis_tlast_reg;

    -- Proceso principal sincronizado con el clock
    process(aclk)
    begin
        if rising_edge(aclk) then

            -- Reset activo en bajo
            if aresetn = '0' then

                state             <= WAIT_SAMPLE;
                s_axis_tready_reg <= '0';
                m_axis_tvalid_reg <= '0';
                m_axis_tdata_reg  <= (others => '0');
                m_axis_tlast_reg  <= '0';

            else

                case state is

                    -- Estado donde el módulo espera una muestra de entrada
                    when WAIT_SAMPLE =>

                        -- Avisamos que estamos listos para recibir una muestra
                        s_axis_tready_reg <= '1';

                        -- Mientras esperamos una muestra, la salida no está marcada como válida
                        m_axis_tvalid_reg <= '0';

                        -- Handshake AXIS de entrada:
                        -- la muestra se acepta solo si TVALID y TREADY están en 1.
                        if s_axis_tvalid = '1' and s_axis_tready_reg = '1' then

                            -- Comprimimos la muestra y guardamos el resultado
                            m_axis_tdata_reg  <= compress_sample(s_axis_tdata);

                            -- Propagamos TLAST. No lo modificamos, solo lo copiamos.
                            m_axis_tlast_reg  <= s_axis_tlast;

                            -- La salida ya tiene un dato válido
                            m_axis_tvalid_reg <= '1';

                            -- Bajamos ready para no aceptar otra muestra mientras enviamos esta
                            s_axis_tready_reg <= '0';

                            -- Pasamos al estado de envío
                            state             <= SEND_SAMPLE;

                        end if;

                    -- Estado donde el módulo mantiene la salida válida
                    -- hasta que el bloque siguiente la acepte
                    when SEND_SAMPLE =>

                        -- No aceptamos nueva entrada mientras la salida está pendiente
                        s_axis_tready_reg <= '0';

                        -- Mantenemos la salida válida
                        m_axis_tvalid_reg <= '1';

                        -- Handshake AXIS de salida:
                        -- si el bloque siguiente está listo, entregamos el dato.
                        if m_axis_tready = '1' then

                            -- Una vez aceptado el dato, bajamos valid
                            m_axis_tvalid_reg <= '0';

                            -- Volvemos a esperar la siguiente muestra
                            state             <= WAIT_SAMPLE;

                        end if;

                end case;

            end if;

        end if;
    end process;

end architecture;
