GHDL = ghdl
GHDL_FLAGS = --std=08 --workdir=work
GTKWAVE = gtkwave

SRC_DIR = src
TB_DIR = testbench
WORK_DIR = work

SOURCES = \
	$(SRC_DIR)/elevator_pkg.vhd \
	$(SRC_DIR)/elevator_controller.vhd \
	$(SRC_DIR)/elevator_scheduler.vhd \
	$(SRC_DIR)/elevator_system.vhd

TESTBENCHES = \
	$(TB_DIR)/elevator_system_tb.vhd

TB_EXEC = elevator_system_tb
WAVE_FILE = $(TB_EXEC).ghw

.PHONY: all clean analyze elaborate run wave help

all: run

$(WORK_DIR):
	@echo "Criando diretório de trabalho..."
	@mkdir -p $(WORK_DIR)

analyze: $(WORK_DIR)
	@echo "================================================"
	@echo "Analisando arquivos VHDL..."
	@echo "================================================"
	@for file in $(SOURCES) $(TESTBENCHES); do \
		echo "Analisando $$file..."; \
		$(GHDL) -a $(GHDL_FLAGS) $$file || exit 1; \
	done
	@echo "Análise concluída com sucesso!"
	@echo ""

elaborate: analyze
	@echo "================================================"
	@echo "Elaborando testbench..."
	@echo "================================================"
	$(GHDL) -e $(GHDL_FLAGS) $(TB_EXEC)
	@echo "Elaboração concluída com sucesso!"
	@echo ""

run: elaborate
	@echo "================================================"
	@echo "Executando simulação..."
	@echo "================================================"
	$(GHDL) -r $(GHDL_FLAGS) $(TB_EXEC) --wave=$(WAVE_FILE) --stop-time=500us
	@echo ""
	@echo "================================================"
	@echo "Simulação concluída!"
	@echo "Arquivo de onda gerado: $(WAVE_FILE)"
	@echo "================================================"
	@echo ""

wave: $(WAVE_FILE)
	@echo "Abrindo GTKWave..."
	$(GTKWAVE) $(WAVE_FILE) &

view:
	@if [ -f $(WAVE_FILE) ]; then \
		echo "Abrindo GTKWave..."; \
		$(GTKWAVE) $(WAVE_FILE) &; \
	else \
		echo "Erro: Arquivo $(WAVE_FILE) não encontrado."; \
		echo "Execute 'make run' primeiro."; \
	fi

clean:
	@echo "Limpando arquivos gerados..."
	@rm -rf $(WORK_DIR)
	@rm -f *.o *.cf $(TB_EXEC) $(WAVE_FILE)
	@echo "Limpeza concluída!"

check: $(WORK_DIR)
	@echo "Verificando sintaxe dos arquivos..."
	@for file in $(SOURCES) $(TESTBENCHES); do \
		echo "Verificando $$file..."; \
		$(GHDL) -s $(GHDL_FLAGS) $$file || exit 1; \
	done
	@echo "Verificação concluída!"