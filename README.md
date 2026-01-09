# Análise de Discurso e Mineração de Texto em Políticas Públicas

Este repositório contém o pipeline de análise de dados desenvolvido em **R** para monitorar a evolução e o enquadramento (*framing*) de políticas socioambientais no Brasil. 

O projeto utiliza técnicas de **Processamento de Linguagem Natural (NLP)** para transformar documentos burocráticos (leis, decretos e relatórios técnicos) em inteligência estratégica, identificando padrões de prioridade governamental e lacunas sociais.

## 🎯 Objetivo da Análise
Investigar como o Estado comunica suas políticas de transferência de renda para conservação ambiental (Programa Bolsa Verde), respondendo a perguntas como:
- **Framing:** A política é tratada como "proteção social/direitos" ou "controle/punição"?
- **Evolução:** Como as prioridades mudaram ao longo das gestões (2011-2024)?
- **Geografia:** Quais biomas (Amazônia, Cerrado, Caatinga) dominam a pauta pública?

## 🛠 Ferramentas e Bibliotecas
O código foi estruturado no **RStudio** utilizando as seguintes bibliotecas:
- **Manipulação de Dados:** `tidyverse` (`dplyr`, `tidyr`, `purrr`)
- **Mineração de Texto:** `tidytext`, `pdftools`, `stopwords`
- **Modelagem Estatística:** `topicmodels` (LDA - Latent Dirichlet Allocation)
- **Visualização de Dados:** `ggplot2`, `ggraph`, `igraph`, `viridis`

## 📊 Destaques Metodológicos
1. **Limpeza de Corpus:** Tratamento de PDFs não estruturados e remoção de ruído jurídico/administrativo.
2. **Análise de Sentimento e Framing:** Classificação de termos para identificar viés punitivo vs. assistencialista.
3. **Modelagem de Tópicos (LDA):** Identificação não-supervisionada dos principais eixos temáticos da documentação.
4. **Análise de Redes:** Visualização de bigramas para entender a estrutura semântica dos documentos.

## 🚀 Como executar
O script `analise_discurso_bolsa_verde.R` espera uma pasta contendo arquivos `.pdf` de documentos oficiais. O código executa o pipeline completo: da ingestão bruta à geração dos gráficos analíticos.

---
*Este projeto foi desenvolvido como parte de pesquisa de Mestrado em Ciência Política, com foco em análise de dados para o setor público e socioambiental.*
