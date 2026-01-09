# ==============================================================================
# PROJETO: Análise de Discurso de Políticas Públicas (Programa Bolsa Verde)
# AUTORA: Agnes Amaral
# DESCRIÇÃO: Pipeline de NLP (Processamento de Linguagem Natural) para analisar
# a evolução narrativa, enquadramento (framing) e foco geográfico da política.
# ==============================================================================

# 1. SETUP E BIBLIOTECAS
# ------------------------------------------------------------------------------
# Carregamento de pacotes para manipulação de texto, dados e visualização
library(pdftools)     # Leitura de PDFs
library(dplyr)        # Manipulação de dados
library(tibble)       # Estrutura de Dataframes
library(tidytext)     # Tokenização e Text Mining
library(stopwords)    # Remoção de palavras comuns
library(purrr)        # Programação funcional
library(ggplot2)      # Visualização de dados
library(topicmodels)  # Modelagem de Tópicos (LDA)
library(viridis)      # Paletas de cores acessíveis
library(stringr)      # Manipulação de strings
library(tidyr)        # Organização de dados (Tidy Data)
library(igraph)       # Análise de Redes
library(ggraph)       # Visualização de Redes

# 2. INGESTÃO DE DADOS (ETL)
# ------------------------------------------------------------------------------
# Defina aqui o diretório onde estão os PDFs do Diário Oficial/Relatórios
caminho_pasta <- "dados/Corpus_LDA" # Caminho relativo para portfólio
arquivos_pdf <- list.files(path = caminho_pasta, pattern = "\\.pdf$", full.names = TRUE)

# Leitura e estruturação do Corpus em Dataframe
docs <- tibble(
  document_id = basename(arquivos_pdf),
  texto = map_chr(arquivos_pdf, ~ paste(pdf_text(.), collapse = " "))
)

# 3. LIMPEZA E PRÉ-PROCESSAMENTO (DATA CLEANING)
# ------------------------------------------------------------------------------
stopwords_pt <- stopwords::stopwords("pt")

# Criação de dicionário de Stopwords personalizado (Domain-Specific)
custom_stopwords <- c(
  # Termos institucionais/ruído
  "programa", "bolsa", "verde", "pbv", "floresta", "brasil", "federal", 
  "nacional", "governo", "ministério", "art", "nº", "decreto", "lei", 
  "inc", "caput", "parágrafo", "http", "https", "www", "gov", "br", "pdf",
  # Stopwords agressivas (filtragem de ruído visual)
  "figura", "tabela", "quadro", "gráfico", "fonte", "elaboração", "própria",
  "ser", "estar", "ter", "haver", "fazer", "ir", "poder", "dever"
)

todas_stopwords <- unique(c(stopwords_pt, custom_stopwords))

# Tokenização e Remoção de Stopwords
palavras_docs <- docs %>%
  unnest_tokens(palavra, texto) %>%
  filter(!palavra %in% todas_stopwords) %>%
  filter(!grepl("[0-9]", palavra)) %>% # Remove números isolados
  filter(nchar(palavra) > 2)         # Remove palavras muito curtas

# 4. ANÁLISE EXPLORATÓRIA: TF-IDF (TERMOS MAIS RELEVANTES)
# ------------------------------------------------------------------------------
# Contagem e cálculo de relevância por documento
palavras_tf_idf <- palavras_docs %>%
  count(document_id, palavra, sort = TRUE) %>%
  bind_tf_idf(palavra, document_id, n) %>%
  arrange(desc(tf_idf))

# Visualização: Top 5 palavras por documento (Diagnóstico inicial)
palavras_top_tfidf <- palavras_tf_idf %>%
  group_by(document_id) %>%
  slice_max(tf_idf, n = 5) %>%
  ungroup() %>%
  mutate(document_id = factor(document_id, levels = docs$document_id))

ggplot(palavras_top_tfidf, aes(x = reorder_within(palavra, tf_idf, document_id), 
                               y = tf_idf, fill = document_id)) +
  geom_col(show.legend = FALSE) +
  scale_x_reordered() + 
  facet_wrap(~ document_id, scales = "free_y") + 
  coord_flip() +
  labs(title = "Palavras Distintivas por Documento (TF-IDF)",
       x = "Palavra", y = "Relevância Estatística") +
  theme_minimal()

# 5. MODELAGEM DE TÓPICOS (LDA - Latent Dirichlet Allocation)
# ------------------------------------------------------------------------------
# Criação da Document-Term Matrix (DTM)
dtm <- palavras_docs %>%
  count(document_id, palavra, sort = TRUE) %>%
  cast_dtm(document_id, palavra, n)

# Execução do Modelo (k=3 tópicos latentes)
lda_model <- LDA(dtm, k = 3, control = list(seed = 1234))

# Visualização dos Tópicos (Probabilidade Beta)
tidy(lda_model, matrix = "beta") %>%
  group_by(topic) %>%
  slice_max(beta, n = 10) %>%
  ungroup() %>%
  arrange(topic, -beta) %>%
  ggplot(aes(x = reorder_within(term, beta, topic), y = beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  scale_x_reordered() +
  facet_wrap(~ paste("Tópico Identificado", topic), scales = "free_y") +
  coord_flip() +
  scale_fill_viridis_d() +
  labs(title = "Modelagem de Tópicos: Principais temas do discurso",
       x = "Termo", y = "Probabilidade Beta") +
  theme_minimal()

# 6. ANÁLISE DE FRAMING (ENQUADRAMENTO DA POLÍTICA)
# ------------------------------------------------------------------------------
# Análise baseada em dicionários: Punição vs. Proteção Social
termos_punicao <- c("fiscaliz", "infracao", "crime", "monitora", "exclusao", "cancel", "autuac", "ibama", "policia")
termos_protecao <- c("apoio", "assisten", "fomento", "educa", "capacita", "garantia", "direito", "cidadania", "inclusao")

analise_framing <- palavras_docs %>%
  mutate(
    frame_postura = case_when(
      str_detect(palavra, paste(termos_punicao, collapse = "|")) ~ "Controle e Punição",
      str_detect(palavra, paste(termos_protecao, collapse = "|")) ~ "Apoio e Proteção Social",
      TRUE ~ NA_character_
    )
  )

# Visualização Divergente (Balanço da Política)
analise_framing %>%
  filter(!is.na(frame_postura)) %>%
  count(frame_postura) %>%
  mutate(n_plot = ifelse(frame_postura == "Controle e Punição", -n, n)) %>%
  ggplot(aes(x = "Balanço", y = n_plot, fill = frame_postura)) +
  geom_col(width = 0.5) +
  coord_flip() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("Apoio e Proteção Social" = "#2E8B57", "Controle e Punição" = "#B22222")) +
  labs(title = "Análise de Framing: O viés da política pública",
       subtitle = "Comparativo de frequência entre termos de assistência social vs. polícia/fiscalização",
       y = "Frequência de Termos", x = NULL, fill = "Enquadramento") +
  theme_minimal() +
  theme(legend.position = "bottom")

# 7. ANÁLISE DE REDES DE BIGRAMAS (CO-OCORRÊNCIA)
# ------------------------------------------------------------------------------
# Entendendo a estrutura semântica: quais palavras aparecem juntas?
bigram_graph <- docs %>%
  unnest_tokens(bigram, texto, token = "ngrams", n = 2) %>%
  separate(bigram, c("palavra1", "palavra2"), sep = " ") %>%
  filter(!palavra1 %in% todas_stopwords, !palavra2 %in% todas_stopwords) %>%
  count(palavra1, palavra2, sort = TRUE) %>%
  filter(n > 10) %>% # Filtro de relevância visual
  graph_from_data_frame()

# Plotagem da Rede Semântica
set.seed(2024)
ggraph(bigram_graph, layout = "fr") +
  geom_edge_link(aes(edge_alpha = n), arrow = grid::arrow(type = "closed", length = unit(.1, "inches"))) +
  geom_node_point(color = "lightblue", size = 4) +
  geom_node_text(aes(label = name), vjust = 1, hjust = 1) +
  labs(title = "Rede Semântica da Política Pública",
       subtitle = "Conexões mais fortes entre termos nos documentos oficiais") +
  theme_void()
