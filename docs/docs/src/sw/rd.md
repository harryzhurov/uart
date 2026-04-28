## Блоки рандомизации данных

Генерация данных, флагов и задержек с заданными вероятностными распределениями осуществляется с помощью классов рандомизации – txRandomizer и rxRandomizer.

### Class txRandomizer

Отвечает за генерацию случайных параметров для передатчика:

* `data` – 8-битное значение [0:255]
* `zero_data` - вес вероятности для `data = 0x00`
* `send_del_exist` - вес вероятности появления задержки перед отправкой новых данных
* `data_delay` – задержка перед началом передачи [0:send_del_dist]
* `send_del_dist` - максимальное значение задержки в тактах `clk`
* `send_del` – флаг наличия задержки (вероятность задаётся параметром `send_del_exist`).

**Код класса рандомизации для передатчика**

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

Веса и максимальное значение задержки задаются параметрами `tx_cfg`:

```
typedef struct {
    int zero_data        = 100;  // probability of data = 2'h00 (1%)
    int send_del_exist   = 1000;  // probobility of delay existance before data sending (10%)
    int send_del_dist    = 5000; // in range [0:5000] clk cycles
    } 
    tx_random_t;
    tx_random_t tx_cfg;
```

где вес в процентном отношении считается по формуле (пример для `zero_data`):

$$
P\Biggr|_{\displaystyle data = 0x00} = \frac{zero  data}{100}
$$

### Class rxRandomizer

Отвечает за генерацию случайных параметров для приемника:

* `data` – 8-битное значение [0:255]
* `zero_data` - вес вероятности для `data = 0x00`
* `send_del_exist` - вес вероятности появления задержки перед отправкой новых данных
* `send_delay` – задержка перед началом передачи [0:send_del_dist]
* `send_del_dist` - максимальное значение задержки перед отправкой данных в тактах `clk`
* `send_del` – флаг наличия задержки перед отправкой данных (вероятность задаётся параметром `send_del_exist`)
* `wrong_stop_exist` - вес вероятности некорректного стоп-бита
* `stop_bit` - стоп бит (вероятность задаётся параметром `wrong_stop_exist`)
* `rden_del_exist` - вес вероятности наличия задержки перед отправкой флага `rx_rden`
* `rden_del_dist` - максимальное значение задержки `rx_rden` в тактах `clk`
* `rden_delay` - задержка перед началом отправки флага `rx_rden` [0:rden_del_dist]
* `wrong_rden` - флаг наличия задержки перед отправкой флага `rx_rden`.

**Код класса рандомизации для приемника**

```
class rxRandomizer;
    int wrong_stop_exist;
    int send_del_exist;
    int send_del_dist;
    int rden_del_exist;
    int rden_del_dist;
    int zero_data;

    rand bit       stop_bit;
    rand bit       send_del;
    rand bit       wrong_rden;
    rand int       send_delay;
    rand int       rden_delay;
    rand bit [7:0] data;
    
    function new(rx_random_t rx_cfg);
        wrong_stop_exist = rx_cfg.wrong_stop_exist;
        send_del_exist   = rx_cfg.send_del_exist;
        send_del_dist    = rx_cfg.send_del_dist;
        rden_del_exist   = rx_cfg.rden_del_exist;
        rden_del_dist    = rx_cfg.rden_del_dist;
        zero_data        = rx_cfg.zero_data;
    endfunction
    
    constraint cst 
    {
        data       inside {[0:255          ]};
        rden_delay inside {[0:rden_del_dist]};
        send_delay inside {[0:send_del_dist]};
        
        stop_bit    dist {0 := (wrong_stop_exist/100)        , 1 := (100 - wrong_stop_exist/100) };
        send_del    dist {0 := (100 - (send_del_exist/100))  , 1 := (send_del_exist/100)         };
        wrong_rden  dist {0 := (100 - (rden_del_exist/100))  , 1 := (rden_del_exist/100)         };
        data        dist {0 := (zero_data/100)               , [1:255] := (100 - (zero_data/100))};
    }

endclass
```

Веса и максимальное значение задержки задаются параметрами `rx_cfg`:

```
typedef struct {
    int wrong_stop_exist = 200;  // probability of stop bit = 0 (2%)
    int send_del_exist   = 200;  // probability of delay existance before data sending (2%)
    int send_del_dist    = 10000;// in range [0:10000] clk cycles
    int rden_del_exist   = 1000;  // probability of delay existance before rx_rden flag sending (10%)
    int rden_del_dist    = 10000;// in range [0:10000] clk cycles
    int zero_data        = 500;  // probability of data = 2'h00 (5%)
    } 
    rx_random_t;
    rx_random_t rx_cfg;
```
