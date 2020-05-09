library(tidyverse)

# Read in ProwessDx dataset of top 100 CSR donors
prowess_raw <- read.delim("./pbt_csr_2009_19_inr/44635_1_70_20200408_211329_dat.txt", 
                          header = TRUE, sep="|")

# Read in data for banks and drop all but Punjab National Bank and State Bank of India. 
# These were not included in the Top 100 dataset becaues they do not have a Corporate 
# Identification Number (CIN).

prowess_banks <- read.delim("./pbt_csr_banks/45455_1_70_20200501_213223_dat.txt",
                            header = TRUE, sep = "|")
prowess_banks <- prowess_banks %>% filter(sa_company_name == "PUNJAB NATIONAL BANK" | 
                                            sa_company_name == "STATE BANK OF INDIA")

# Merge the two Prowess datasets 

prowess_raw <- bind_rows(prowess_raw, prowess_banks)

# Create fiscal years variable based on date of company annual report filing

prowess_raw <- prowess_raw %>% 
  mutate(year = recode(sa_finance1_year, 
                       `20080331` = "2007_08", `20090331` = "2008_09", `20100331` = "2009_10", 
                       `20110331` = "2010_11", `20120331` = "2011_12", `20130331` = "2012_13", 
                       `20140331` = "2013_14", `20150331` = "2014_15", `20160331` = "2015_16", 
                       `20170331` = "2016_17", `20180331` = "2017_18", `20190331` = "2018_19", 
                       `20081231` = "2007_08", `20091231` = "2008_09", `20101231` = "2009_10", 
                       `20111231` = "2010_11", `20121231` = "2011_12", `20131231` = "2012_13", 
                       `20141231` = "2013_14", `20151231` = "2014_15", `20161231` = "2015_16", 
                       `20171231` = "2016_17", `20181231` = "2017_18", `20191231` = "2018_19", 
                       `20080630` = "2007_08", `20090630` = "2008_09", `20100630` = "2009_10", 
                       `20110630` = "2010_11", `20120630` = "2011_12", `20130630` = "2012_13", 
                       `20140630` = "2013_14", `20150630` = "2014_15"))

# The Prowess dataset has two variables for CSR spending. 
# Take the larger of sa_csr_amt_spent_during_the_year and csr_total_amt_spent.

prowess_raw <- prowess_raw %>% 
  mutate (csr_spending = 
            pmax(sa_csr_total_amt_spent, sa_csr_amt_spent_during_the_year, na.rm = TRUE))

# Prepare prowess_raw for merge with my dataset by standardizing company_name variable and 
# making the name of Indus Towers Ltd consistent between the two datasets.

prowess_raw <- rename(prowess_raw, company_name = sa_company_name)

prowess_raw <- prowess_raw %>% 
  mutate(company_name = recode(company_name, 
                               `INDUS TOWERS LTD. [MERGED]` = "INDUS TOWERS LTD."))

# Calculate the average net profit (profit before tax) for three preceding fiscal years, 
# for 2013-14, 2012-13, and 2011-12. A year's PBT is provided by the sa_pbt variable.
# If any of three three years is not available, return NA.
# TODO: refactor this code.

# 2013-14 3-yr avg PBT

prowess_calculated_2013_14a <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2012_13") %>% select(sa_pbt)
prowess_calculated_2013_14b <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2011_12") %>% select(sa_pbt)
prowess_calculated_2013_14c <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2010_11") %>% select(sa_pbt)

prowess_merge_a <- merge(prowess_calculated_2013_14a, prowess_calculated_2013_14b, 
                         by = "company_name")
prowess_merge_b <- merge(prowess_merge_a, prowess_calculated_2013_14c, 
                         by ="company_name")

prowess_merge_b$sa_pbt_3yr <- (prowess_merge_b$sa_pbt.x + prowess_merge_b$sa_pbt.y + 
                                 prowess_merge_b$sa_pbt)/3
prowess_merge_b <- prowess_merge_b[c("company_name", "sa_pbt_3yr")]
prowess_merge_b$year <- "2013_14"

# 2012-13 3-yr avg PBT

prowess_calculated_2012_13a <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2011_12") %>% select(sa_pbt)
prowess_calculated_2012_13b <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2010_11") %>% select(sa_pbt)
prowess_calculated_2012_13c <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2009_10") %>% select(sa_pbt)

prowess_merge_a <- merge(prowess_calculated_2012_13a, prowess_calculated_2012_13b, 
                         by = "company_name")
prowess_merge_c <- merge(prowess_merge_a, prowess_calculated_2012_13c,
                         by ="company_name")

prowess_merge_c$sa_pbt_3yr <- (prowess_merge_c$sa_pbt.x + prowess_merge_c$sa_pbt.y + 
                                 prowess_merge_c$sa_pbt)/3
prowess_merge_c <- prowess_merge_c[c("company_name", "sa_pbt_3yr")]
prowess_merge_c$year <- "2012_13"

# 2011-12 3-yr avg PBT

prowess_calculated_2011_12a <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2010_11") %>% select(sa_pbt)
prowess_calculated_2011_12b <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2009_10") %>% select(sa_pbt)
prowess_calculated_2011_12c <- prowess_raw %>% group_by(company_name) %>% 
  filter(year == "2008_09") %>% select(sa_pbt)

prowess_merge_a <- merge(prowess_calculated_2011_12a, prowess_calculated_2011_12b,
                         by = "company_name")
prowess_merge_d <- merge(prowess_merge_a, prowess_calculated_2011_12c,
                         by ="company_name")
prowess_merge_d <- prowess_merge_d

prowess_merge_d$sa_pbt_3yr <- (prowess_merge_d$sa_pbt.x + prowess_merge_d$sa_pbt.y + 
                                 prowess_merge_d$sa_pbt)/3
prowess_merge_d <- prowess_merge_d[c("company_name", "sa_pbt_3yr")]
prowess_merge_d$year = "2011_12"

# Add average PBT to appropriate dataframe column.

prowess_calculated <- full_join(prowess_raw, prowess_merge_b, 
                                by=c("company_name", "year"))
prowess_calculated <- left_join(prowess_calculated, prowess_merge_c,
                                by=c("company_name", "year"))
prowess_calculated <- left_join(prowess_calculated, prowess_merge_d, 
                                by=c("company_name", "year"))

# Create master variable for required CSR spending amount.

prowess_calculated <- prowess_calculated %>% 
  mutate(pbt_3yr = pmax(sa_pbt_3yr.x, sa_pbt_3yr.y, sa_pbt_3yr, 
                        sa_csr_avg_net_profit_last_3_years, na.rm = TRUE))

# Retain only essential columns and rows for export.

prowess_calculated <- prowess_calculated[c("company_name", "year", "sa_pbt", 
                                           "csr_spending", "pbt_3yr")]

# Read in the CSR expenditure data I collected manually for the 
# three years prior to 2014-15.

sams_data <- read_csv("./csr_before", col_names = TRUE)
sams_data <- rename(sams_data, rank_csr = csr_total_rank)

# Reshape my CSR data from wide format to long.

sams_long <- pivot_longer(sams_data, cols = starts_with("csr"), names_to = "year", 
                          names_pattern = "(\\d\\d\\d\\d_\\d\\d)", 
                          values_to = "csr_spending")

# Join my data to ProwessDx dataset.

all_data <- full_join(sams_long, prowess_calculated, by = c("company_name", "year"))
all_data <- all_data %>% mutate (csr_spending = pmax(csr_spending.x, 
                                                     csr_spending.y, na.rm = TRUE))

# Drop extraneous columns.

all_data <- subset(all_data, select=-c(csr_spending.x, csr_spending.y))

# Fill CINs and public/private ownership from my dataset into the full dataframe.

all_data <- all_data %>% group_by(company_name) %>% fill(public, cin, rank_csr)

# Punjab National Bank, State Bank of India, and Bank of America do not have 
# 3-year PBT figures in the Prowess Dataset. Calculate these figures.

# Generate an observation ID
all_data <- all_data[order(all_data$company_name, all_data$year),]
all_data$id <- seq.int(nrow(all_data))

# Add calculations for Punjab National Bank
all_data[all_data$id==861, "pbt_3yr"] <- round(((46933.8 + 65248.2 + 70449.2) / 3), 
                                               digits = 1) # 2014-15
all_data[all_data$id==862, "pbt_3yr"] <- round(((39602.3 + 46933.8 + 65248.2) / 3), 
                                               digits = 1) # 2015-16
all_data[all_data$id==863, "pbt_3yr"] <- round(((-39686.0 + 39602.3 + 46933.8) / 3), 
                                               digits = 1) # 2016-17
all_data[all_data$id==864, "pbt_3yr"] <- round(((20115.4 - 39686.0 + 39602.3) / 3), 
                                               digits = 1) # 2017-18
all_data[all_data$id==865, "pbt_3yr"] <- round(((-122828.2 + 20115.4 - 39686.0) / 3), 
                                               digits = 1) # 2018-19

# Add calculations for State Bank of India
all_data[all_data$id==983, "pbt_3yr"] <- round(((163161.6 + 199508.9 + 185045.9) / 3), 
                                               digits = 1) # 2014-15
all_data[all_data$id==984, "pbt_3yr"] <- round(((193531.2 + 163161.6 + 199508.9) / 3), 
                                               digits = 1) # 2015-16
all_data[all_data$id==985, "pbt_3yr"] <- round(((141993.9 + 193531.2 + 163161.6) / 3), 
                                               digits = 1) # 2016-17
all_data[all_data$id==986, "pbt_3yr"] <- round(((149877.1 + 141993.9 + 193531.2) / 3), 
                                               digits = 1) # 2017-18
all_data[all_data$id==987, "pbt_3yr"] <- round(((-155282.4 + 149877.1 + 141993.9) / 3),
                                               digits = 1) # 2018-19

# Add calculations for Bank of America
all_data[all_data$id==109, "pbt_3yr"] <- round(((12300.6 + 8141.0 + 8556.0) / 3), 
                                               digits = 1) # 2014-15
all_data[all_data$id==110, "pbt_3yr"] <- round(((10507.9+ 12300.6 + 8141.0) / 3), 
                                               digits = 1) # 2015-16
all_data[all_data$id==111, "pbt_3yr"] <- round(((11919.4 + 10507.9 + 12300.6) / 3), 
                                               digits = 1) # 2016-17
all_data[all_data$id==112, "pbt_3yr"] <- round(((12171.3+ 11919.4 + 10507.9) / 3), 
                                               digits = 1) # 2017-18
all_data[all_data$id==113, "pbt_3yr"] <- round(((13044.5 + 12171.3+ 11919.4) / 3), 
                                               digits = 1) # 2018-19

# Calculate the current year's CSR spending as percentage of previous three years' 
# average profit before tax.

all_data$spending_pbt3_pct <- round(((all_data$csr_spending / all_data$pbt_3yr) * 100), 
                                    digits = 2)

# Export the data to CSV.

export_data <- all_data %>% filter(year == "2011_12" | year == "2012_13" | year == "2013_14" | 
                                     year == "2014_15" | year == "2015_16" | year == "2016_17" |
                                     year == "2017_18" | year == "2018_19")

write_excel_csv(export_data, "csr_data_full.csv")
