# Симуляция в testbench

Для проверки работоспобности написан testbench. 

Генерация данных осуществляется с помощью class:

**Пример для передатчика**

```
class txRandomizer;
    int zero_data;
    int send_del_exist;
    int send_del_dist;

    rand bit       send_del;
    rand bit [7:0] data;
    rand int       data_delay;

    function new(tx_random_t tx_cfg);
        zero_data      = tx_cfg.zero_data;
        send_del_exist = tx_cfg.send_del_exist;
        send_del_dist  = tx_cfg.send_del_dist;
    endfunction
    
    constraint cst
    {
        data       inside {[0:255          ]};
        data_delay inside {[0:send_del_dist]};
        
        send_del   dist {0 := (100 - (send_del_exist/100)), 1 := (send_del_exist/100)};
    }
    
endclass
```
Веса и диапазон задержек задаются параметрами:

**Пример для передатчика**

```
typedef struct {
    int zero_data        = 100;  // probability of data = 2'h00 (1%)
    int send_del_exist   = 1000;  // probobility of delay existance before data sending (10%)
    int send_del_dist    = 5000; // in range [0:5000] clk cycles
    } 
    tx_random_t;
    tx_random_t tx_cfg;
```

Для задания веса в процентном отношении необходимо задать число от 0 до 10000. Формула вычисления веса на примере `zero_data`:

$$
P\Biggr|_{\displaystyle data = 0x00} = \frac{zero data}{100}
$$

## Драйвер



![](uart_tb.drawio)
