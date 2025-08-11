## Репозиторій з особистими скриптами щоб не загубити.  

- [WoL Enable Service](https://github.com/dima101097/linux/tree/main/WoL_Enable) - Служба автоматично вмикає WoL в linux після увімкнення. Потрібно в випадку якщо самостійно це не відбувається 
```sh
    Зберігти WoL_Enable.sh в зручному місці, замінив ім'я інтрфейсу.
    Створити сервіс wol_enable.service за шляхом /lib/systemd/system/ та вказатишлях до sh скрипта.
    Віиконати sudo systemctl enable wol_enable.service 
 ```
___
- [Silent minute](https://github.com/dima101097/linux/tree/main/Silent_minute) - Скрипт відтворення хвилини мовчання. Для автоматичного відтворення в 9 ранку щодня неодхідно в crontab додати 
```sh
    0 9 * * * /.../Start.bash >> /dev/null

 ```
___
- [Add user](https://github.com/dima101097/linux/blob/main/adduser.bash) - Скрипт для спрощення рутинних дій, створює нового користувача, дає права використання sudo, та для безпеки деактивовує root користувача.
```sh
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/dima101097/linux/refs/heads/main/adduser.bash)"
 ```
___
- [FileBrowser](https://github.com/dima101097/linux/blob/main/FileBrowser.bash) - Скрипт для автовстановлення FileBrowser. 
```sh
    sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/dima101097/linux/refs/heads/main/FileBrowser.bash)"
 ```   
___
- [iVentoy](https://github.com/dima101097/linux/blob/main/iventoy.bash) - Скрипт для автовстановлення iVentoy PXE. 
```sh
    sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/dima101097/linux/refs/heads/main/iventoy.bash)"
 ```   
 ___
- [disable-offload.service](https://github.com/dima101097/linux/blob/main/disable-offload.service) - На моєму Intel NUC інколи виникає проблема з мережевим інтерфейсом, наступний сервіс вимикає прискорення тимсамим проблема вирішується. В сервісі необхідно змінити імя інтерфейса.
Запуск сервісу
```sh
sudo systemctl daemon-reload
sudo systemctl enable disable-offload
```

Вивод команди dmesg з помилкою
```sh
     Detected Hardware Unit Hang:
                   TDH                  <b7>
                   TDT                  <1>
                   next_to_use          <1>
                   next_to_clean        <b6>
                 buffer_info[next_to_clean]:
                   time_stamp           <14448066d>
                   next_to_watch        <b7>
                   jiffies              <14449f9c0>
                   next_to_watch.status <0>
                 MAC Status             <80083>
                 PHY Status             <796d>
                 PHY 1000BASE-T Status  <7c00>
                 PHY Extended Status    <3000>
                 PCI Status             <10>
 ```





