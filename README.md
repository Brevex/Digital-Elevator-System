# Projeto Sistema de Controle de Elevadores em VHDL

Este projeto implementa um sistema de controle para 3 elevadores em um edifício de 32 andares, utilizando VHDL. A arquitetura é dividida em dois níveis:

1.  **Controlador Local (`elevator_controller.vhd`):** Uma FSM por elevador que gerencia o motor, portas e estado individual.
2.  **Escalonador (`elevator_scheduler.vhd`):** Um módulo supervisor central que recebe chamadas externas e aloca o elevador mais apropriado com base em um algoritmo de custo.

## 🛠️ Ferramentas e Requisitos

Para simular este projeto, você precisará das seguintes ferramentas instaladas:

- **GHDL:** Um simulador VHDL de código aberto.
- **GTKWave:** Um visualizador de formas de onda.
- **Make**: Para usar o Makefile fornecido.

## 🚀 Instruções de Simulação

O `Makefile` fornecido automatiza todo o processo. Abra um terminal na raiz do projeto e execute os seguintes comandos:

### 1. Compilar e Executar a Simulação

Este é o comando principal. Ele irá compilar todos os arquivos VHDL, executar a simulação completa e gerar o arquivo de forma de onda (`elevator_system_tb.ghw`).

```bash
make run
```

### 2. Visualizar os Resultados

Após a execução da simulação, use este comando para abrir o arquivo de forma de onda gerado (.ghw) no GTKWave:

```bash
make wave
```

### 3. Limpar Arquivos Gerados

Para remover o diretório work/, o executável do testbench e o arquivo .ghw, execute:

```bash
make clean
```
