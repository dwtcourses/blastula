library(blastula)
library(tidyverse)
library(gt)
library(scales)
library(emo)
library(glue)

# Attribution Information available in `README-attribution.txt`

# Create short labels for months (displays
# better for small plots in email messages)
initial_months <-
  c("D",
    "J", "F", "M", "A", "M", "J",
    "J", "A", "S", "O", "N", "D",
    "J")

# Create a plot using the `pizzaplace` dataset
pizza_plot <-
  pizzaplace %>%
  mutate(type = str_to_title(type)) %>%
  mutate(date = as.Date(date)) %>%
  group_by(date, type) %>%
  summarize(Pizzas = n(), Income = sum(price)) %>%
  ungroup() %>%
  ggplot() +
  geom_point(aes(x = date, y = Income), color = "steelblue") +
  facet_wrap(~type) +
  scale_x_date(date_breaks = "1 month", date_labels = initial_months) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "pizzaplace: Daily Pizza Sales in 2015",
    subtitle = "Faceted by the type of pizza",
    x = NULL,
    y = "Number of Pizzas Sold") +
  theme_minimal() +
  theme(
    axis.text = element_text(color = "grey25"),
    axis.text.x = element_text(size = 6),
    axis.text.y = element_text(size = 8),
    strip.text.x = element_text(size = 9),
    axis.title = element_text(color = "grey25"),
    legend.title = element_text(color = "grey25"),
    legend.text = element_text(color = "grey25"),
    panel.grid.major = element_line(color = "grey75"),
    plot.title = element_text(color = "grey25"),
    plot.caption = element_text(color = "grey25"),
    plot.subtitle = element_text(color = "grey25"),
    plot.margin = unit(c(20, 20, 20, 20), "points"),
    plot.title.position = "plot",
    legend.box.spacing = unit(2, "points"),
    legend.position = "bottom"
  )

# Make the plot suitable for mailing by
# converting it to an HTML fragment
pizza_plot_email <-
  pizza_plot %>%
  add_ggplot(alt = "Pizza Sales Plots by type of pizza (in 2015)")

# Create `sizes_order` and `types_order` to
# support the ordering of pizza sizes and types
sizes_order <- c("S", "M", "L", "XL", "XXL")
types_order <- c("Classic", "Chicken", "Supreme", "Veggie")

# Create a gt table that uses the `pizzaplace` dataset; ensure that
# `as_raw_html()` is used (that gets us an HTML fragment with inlined
# CSS styles)
pizza_tab_email <-
  pizzaplace %>%
  mutate(type = str_to_title(type)) %>%
  mutate(size = factor(size, levels = sizes_order)) %>%
  mutate(type = factor(type, levels = types_order)) %>%
  group_by(type, size) %>%
  summarize(
    pies = n(),
    income = sum(price)
  ) %>%
  arrange(type, size) %>%
  gt(rowname_col = "size") %>%
  fmt_currency(
    columns = vars(income),
    currency = "USD") %>%
  fmt_number(
    columns = vars(pies),
    use_seps = TRUE,
    decimals = 0
  ) %>%
  summary_rows(
    groups = TRUE,
    columns = "pies",
    fns = list(TOTAL = "sum"),
    formatter = fmt_number,
    use_seps = TRUE,
    decimals = 0
  ) %>%
  summary_rows(
    groups = TRUE,
    columns = "income",
    fns = list(TOTAL = "sum"),
    formatter = fmt_currency,
    currency = "USD"
  ) %>%
  tab_options(
    summary_row.background.color = "#FFFAAA",
    row_group.background.color = "#E6EFFC",
    table.font.size = "small",
    row_group.font.size = "small",
    column_labels.font.size = "small",
    data_row.padding = "5px"
  ) %>%
  cols_label(
    pies = "Pizzas",
    income = "Income"
  ) %>%
  tab_header(
    title = paste0("My ", emo::ji("pizza"), " sales in 2015"),
    subtitle = "Split by the type of pizza and the size"
  ) %>%
  tab_options(table.width = pct(40)) %>%
  as_raw_html()

email <-
  compose_email(body = md(glue("
  Hello,

  Just wanted to let you know that pizza \\
  sales were pretty strong in 2015. When \\
  I look back at the numbers, mega sales. \\
  Not too bad. All things considered.

  Here's a plot of the daily pizza sales. I \\
  faceted by the type of pizza because I know \\
  that's your preference.

  {pizza_plot_email}

  Here is a table that shows a breakdown \\
  of the 2015 results by pizza size, split into \\
  *Pizza Type* groups:

  {pizza_tab_email}

  I also put all the 2015 numbers into an R \\
  dataset called `pizzaplace`. Not sure why \\
  I did that, but I did. It's in the `gt` \\
  package.

  Talk to you later,

  Alfonso
  "
  )))

# Preview the email in the RStudio Viewer
email
