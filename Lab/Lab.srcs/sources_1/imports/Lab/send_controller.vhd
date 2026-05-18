library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity send_controller is
    generic(
        DATA_LENGHT  : positive := 16   -- 2 byte of TDATA in FLOAT COMPRESSOR
    );
    port (
        aclk   : in std_logic;
        aresetn : in std_logic;
        -- AXI4 entrada (muestras comprimiedas desde el compressor).
        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(DATA_LENGHT-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tready	: out std_logic;
        -- AXI4 salida (Envío de datos hacia UART TX)
        m_axis_tvalid	: out std_logic;
        m_axis_tdata	: out std_logic_vector(DATA_LENGHT-1 downto 0);
        m_axis_tready	: in std_logic;

        send_audio    : in std_logic
    );
end entity send_controller;

architecture rtl of send_controller is
    -- Estados de la FSM: 
    
    -- WAIT_PACKED_END:
    -- No se envia nada todavia
    -- Se consume y descarta hasta ver un TLAST = 1
    -- Eso asegura que el siguiente dato será inicio de paquete.
    
    -- WAIT SAMPLE:
    -- Ya se está alineado.
    -- Si send_audio = 1, se acepta la muestra(compressor) para enviar(UART).
    
    -- SEND_SAMPLE:
    --Mantener la salida válida hasta que el siguiente bloque acepte el dato.
    type state_type is (WAIT_PACKET_END, WAIT_SAMPLE, SEND_SAMPLE);
    signal state : state_type := WAIT_PACKET_END;
    -- Internal reg para controlar el ready de entrada
    signal s_axis_tready_reg : std_logic := '0';
    -- Internal regs para la salida AXI
    signal m_axis_tvalid_reg : std_logic := '0';
    signal m_axis_tdata_reg  : std_logic_vector(DATA_LENGHT-1 downto 0) := (others => '0');
    -- Se guarda el TLAST de la muestra actual (saber si la muestra enviada era final de paquete)
    signal current_tlast_reg : std_logic := '0';
    -- Bandera de que se empezó a enviar un paquete, si send audio baja a mitad de paquete
    -- no se corta de una, se sigue hasta ver TLAST para cerrar bien el paquete.
    signal sending_packet_reg : std_logic := '0';

begin
    -- Conexión de internal regs a los ports
    s_axis_tready <= s_axis_tready_reg;

    m_axis_tvalid <= m_axis_tvalid_reg;
    m_axis_tdata  <= m_axis_tdata_reg;
    -- FSM clock syncronised :D
    process(aclk)
    begin
        if rising_edge(aclk) then

            if aresetn = '0' then

                state              <= WAIT_PACKET_END;
                s_axis_tready_reg  <= '0';
                m_axis_tvalid_reg  <= '0';
                m_axis_tdata_reg   <= (others => '0');
                current_tlast_reg  <= '0';
                sending_packet_reg <= '0';

            else

                case state is

                    --------------------------------------------------------------------
                    -- Estado inicial (de descarte), se consumen datos pero no se envian
                 
                    -- Se espera TLAST = 1 para quedar alineados:
                    -- después de un TLAST, el siguiente dato debe ser inicio de paquete.
                    -- Porque el audio viene L, R(TLAST=1) y python espera pares L/R completos.
                    --------------------------------------------------------------------
                    when WAIT_PACKET_END =>
                        -- Recibir, pero para descartar
                        s_axis_tready_reg <= '1';
                        -- No se está enviando nada
                        m_axis_tvalid_reg <= '0';
                        -- Todavía no se está dentro de un paquete enviado
                        sending_packet_reg <= '0';
                        
                        -- Handshake AXI de entrada
                        -- Se consume una muestra cuando TVALID y TREADY estén en 1
                        if s_axis_tvalid = '1' and s_axis_tready_reg = '1' then
                            -- Si la muestra tiene TLAST = '1' se termino el paquete actual
                            -- A partir de la siguiente muestra estoy alineado al inicio de un paquete nuevo
                            if s_axis_tlast = '1' then
                                state <= WAIT_SAMPLE;
                            end if;

                        end if;

                    --------------------------------------------------------------------
                    -- Aki stoi alineados al inicio de un paquete.
                    -- Si send_audio está activo, se toma el dato y se manda.
                    -- Si send_audio está apagado, no se manda todavia.
                    --------------------------------------------------------------------
                    when WAIT_SAMPLE =>
                        -- no hay salida válida mientras esperamos entrada
                        m_axis_tvalid_reg <= '0';
                        -- Si send_audio activo, se empieza o continua enviando
                        -- También continuamos si sendig_packet_reg = 1 porque
                        -- ya empezamos el paquete y toca terminarlo aunque send_audio baje
                        if send_audio = '1' or sending_packet_reg = '1' then
                            -- Listos para recibir muestra
                            s_axis_tready_reg <= '1';
                            -- Handshake AXI de entrada    
                            if s_axis_tvalid = '1' and s_axis_tready_reg = '1' then
                                -- Guardamos el dato que llego para mandarlo a la salida
                                m_axis_tdata_reg  <= s_axis_tdata;
                                -- guardamos si esta muestra era final de paquete
                                current_tlast_reg <= s_axis_tlast;
                                -- Marcamos que la salida viene de un dato valido
                                m_axis_tvalid_reg <= '1';

                                -- Ya empezamos o seguimos enviando un paquete
                                sending_packet_reg <= '1';
                                -- Bajamos ready para esperar a que el siguiente bloque
                                --acepte la salida
                                s_axis_tready_reg <= '0';
                                -- pasamos al estado de envio
                                state <= SEND_SAMPLE;

                            end if;

                        else

                            -- Si send_audio está apagado, se sigue consumiendo/descartando
                            -- hasta quedar sincronizados con el final del paquete.
                            s_axis_tready_reg <= '1';

                            if s_axis_tvalid = '1' and s_axis_tready_reg = '1' then
                                -- Si justo vimos TLAST, seguimos alineados
                                -- Si no, volvemos a esperar el final del paquete.
                                if s_axis_tlast = '1' then
                                    state <= WAIT_SAMPLE;
                                else
                                    state <= WAIT_PACKET_END;
                                end if;
                            end if;

                        end if;

                    --------------------------------------------------------------------
                    -- Estado de salida
                    
                    -- Aquí se mantiene m_axis_tvalid = 1 y m_axis_tdata estable
                    -- hasta que el siguiente bloque diga m_axis_tready = 1
                    --------------------------------------------------------------------
                    when SEND_SAMPLE =>
                        -- no aceptamos nueva entrada mientras la salida este pendiente
                        s_axis_tready_reg <= '0';
                        -- mantenemos la salida valida.
                        m_axis_tvalid_reg <= '1';
                        -- handsahKE AXIS de salida
                        -- el dato se entrega cuando TVALID y TREADY esten en 1
                        if m_axis_tready = '1' then
                            -- una vez fue aceptado, bajamos valid
                            m_axis_tvalid_reg <= '0';

                            -- Si este dato era el final del paquete, ya se puede decidir si
                            -- enviamos o paramos.
                            if current_tlast_reg = '1' then
                                -- ya no estamos dentro de un paquete pendiente
                                sending_packet_reg <= '0';

                                if send_audio = '1' then
                                    -- terminamos un paquete, pero se puede esperar
                                    -- el inciio del siguiente
                                    state <= WAIT_SAMPLE;
                                else
                                    -- cerramos el paquete, paramos limpio.
                                    state <= WAIT_PACKET_END;
                                end if;

                            else

                                -- Todavía no terminó el paquete.
                                -- Aunque send_audio baje, se sigue hasta vver TLAST
                                sending_packet_reg <= '1';
                                state <= WAIT_SAMPLE;

                            end if;

                        end if;

                end case;

            end if;

        end if;
    end process;

end rtl;
