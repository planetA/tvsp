library(tidyverse)
library(ggpubr)

dt <- read_csv("log/log.csv") %>%
    mutate(
        Instructions = Instructions / Rounds / Tasks,
        Cycles = Cycles / Rounds / Tasks,
        Time = Time / Rounds / Tasks * 1e9,
        Mode = if_else(Threads == TRUE, "Threads", "Processes"),
    ) %>%
    select(-Threads)


dt_over <-
    dt %>%
    pivot_wider(names_from = Mode, values_from = Time) %>%
    group_by(CPU) %>%
    summarise(
        Position = max(na.omit(Processes), na.omit(Threads)),
        Relative = na.omit(Processes) / na.omit(Threads),
        Absolute = na.omit(Processes) - na.omit(Threads),
    )

dt %>%
    ggplot(aes(x = CPU, y = Time, fill = Mode)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_label(
        data = dt_over,
        inherit.aes = FALSE,
        aes(
            x = CPU,
            y = Position,
            label = paste0("x", round(Relative, 1), " (", round(Absolute, 1), " ns)"),
        ),
        position = position_dodge(width = 1),
        vjust = -0.5,
    ) +
    labs(x = "CPU", y = "Time, ns") +
    theme_pubr() %+replace% theme(legend.position = "bottom")
ggsave("log/cs_time.png", width = 10, height = 10)

dt_over <-
    dt %>%
    pivot_wider(names_from = Mode, values_from = Instructions) %>%
    group_by(CPU) %>%
    summarise(
        Position = max(na.omit(Processes), na.omit(Threads)),
        Relative = na.omit(Processes) / na.omit(Threads),
        Absolute = na.omit(Processes) - na.omit(Threads),
    )
dt %>%
    ggplot(aes(x = CPU, y = Instructions, fill = Mode)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_label(
        data = dt_over,
        inherit.aes = FALSE,
        aes(
            x = CPU,
            y = Position,
            label = paste0("x", round(Relative, 2), " (", round(Absolute, 1), " instr)"),
        ),
        position = position_dodge(width = 1),
        vjust = -0.5,
    ) +
    labs(x = "CPU", y = "Instructions") +
    theme_pubr() %+replace% theme(legend.position = "bottom")
ggsave("log/cs_instr.png", width = 10, height = 10)

dt_over <-
    dt %>%
    pivot_wider(names_from = Mode, values_from = Cycles) %>%
    group_by(CPU) %>%
    summarise(
        Position = max(na.omit(Processes), na.omit(Threads)),
        Relative = na.omit(Processes) / na.omit(Threads),
        Absolute = na.omit(Processes) - na.omit(Threads),
    )
dt %>%
    ggplot(aes(x = CPU, y = Cycles, fill = Mode)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_label(
        data = dt_over,
        inherit.aes = FALSE,
        aes(
            x = CPU,
            y = Position,
            label = paste0("x", round(Relative, 2), " (", round(Absolute, 1), " cycles)"),
        ),
        position = position_dodge(width = 1),
        vjust = -0.5,
    ) +
    labs(x = "CPU", y = "Cycles") +
    theme_pubr() %+replace% theme(legend.position = "bottom")
ggsave("log/cs_cycles.png", width = 10, height = 10)
