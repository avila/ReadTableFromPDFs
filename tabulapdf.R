# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# read pdf tables ----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## libs ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(readr)
library(tabulapdf)
library(dplyr)
# optional: set memory for Java 
options(java.parameters = "-Xmx24000m") # i think i am setting 24gigs of memory


## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## prep ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# create dir if does not exist
if (!dir.exists("output/")) dir.create("output/")
if (!dir.exists("intermediate//")) dir.create("intermediate//")


pdf_file_name <- "ResCNJ215Anexo08Servidores202410.pdf"
# pdf_file_name <- "pdf_first_page.pdf"

if (FALSE) {
  locate_areas(
    pdf_file_name,
    pages = 1,
    resolution = 60L,
    widget = c("shiny"),
    copy = FALSE
  )  
}

page_dim <- list(
  c(top=136.42129, left=39.02348 , bottom=566.87057, right=803.01206)
)

column_names <- c(
  "Nome",
  "Lotação",
  "Cargo",
  "Remuneração Paradigma (I)",
  "Vantagens Pessoais (II)",
  "Substituições, Diferenças, Subsídios, Função de Confiança ou Cargo em Comissão",
  "Indenizações (III)",
  "Vantagens Eventuais (IV)",
  "Gratificações (V)",
  "Total de Créditos (VI)",
  "Previdência Pública (VII)",
  "Imposto de Renda (VIII)",
  "Descontos Diversos (IX)",
  "Retenção por Teto Constitucional (X)",
  "Total de Débitos (XI)",
  "Rendimentos Líquidos (XII)",
  "Remuneração de Órgão de Origem (XIII)",
  "Diárias (XIV)"
)
length(column_names)


## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## get data ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

extracted_tables <- tabulapdf::extract_tables(
  pdf_file_name,
  col_names = FALSE,
  area = page_dim,
  #pages = 1:2,
  guess = FALSE,
  output = "csv",
  outdir = "intermediate/"
)


## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## get data back together ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

file_list = list.files(path = "intermediate/" , pattern="\\.csv$", full.names = TRUE)

custom_locale <- readr::locale(
  date_names = "br",
  decimal_mark = ",",
  grouping_mark = ".",
  encoding = "UTF-8",
  asciify = FALSE
)

read_csv_custom <- function(x) {
    # read.csv(
    #   x, header = FALSE, sep = ",", quote = "\"",
    #   dec = ".", fill = TRUE, comment.char = "",
    # )
  custom_spec <- readr::cols(
    Nome = col_character(),
    Lotação = col_character(),
    Cargo = col_character(),
    `Remuneração Paradigma (I)` = col_number(),
    `Vantagens Pessoais (II)` = col_number(),
    `Substituições, Diferenças, Subsídios, Função de Confiança ou Cargo em Comissão` = col_double(),
    `Indenizações (III)` = col_number(),
    `Vantagens Eventuais (IV)` = col_number(),
    `Gratificações (V)` = col_number(),
    `Total de Créditos (VI)` = col_number(),
    `Previdência Pública (VII)` = col_number(),
    `Imposto de Renda (VIII)` = col_number(),
    `Descontos Diversos (IX)` = col_number(),
    `Retenção por Teto Constitucional (X)` = col_double(),
    `Total de Débitos (XI)` = col_number(),
    `Rendimentos Líquidos (XII)` = col_number(),
    `Remuneração de Órgão de Origem (XIII)` = col_double(),
    `Diárias (XIV)` = col_number()
  )
  
  readr::read_csv(
    file = x, col_names = column_names, locale = custom_locale,
    col_types = custom_spec
  )
}
myfiles = lapply(file_list, read_csv_custom)

# file page 183 got 19 cols for some reason
# page starts with BRUNO ALVES DO VALLE CORBUCCI
funny_file <- myfiles[[183]]

# remove 19th row of such file
myfiles[[183]]['X19'] <- NULL 
final_df <- data.table::rbindlist(myfiles,fill = FALSE)

### deal with metadata on last page ----
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##' somehow, it was save no as the last dataframe in the list (probably due to)
##' paralell processing
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if (FALSE) {
  # for now, not fixing it...
  # Define the name to search for
  search_name <- "MELINA VIANNA FAVA PRATTA"
  
  # Find indices of data frames containing the name
  matching_indices <- which(sapply(myfiles, function(df) {
    any(apply(df, 1, function(row) any(grepl(search_name, row, ignore.case = TRUE))))
  }))
  
  # Print the indices
  matching_indices
  
  
  
  df_tofix <- myfiles[[matching_indices]]
  df_fixed <- df_tofix |> 
    filter(!grepl("^\\(", Nome)) |> 
    filter(!is.na(Nome)) |> 
    tidyr::separate(Nome, into=c("v1", "v2"), sep="VARA")
  df_fixed
  colnames(df_fixed) <- 
    myfiles[[matching_indices]] <- df_fixed  
}

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## export csv / excel ----
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

write_excel_csv(final_df, "output/final.csv")
openxlsx::write.xlsx(final_df, "output/final.xlsx")
