## Репозиторій з особистими скриптами щоб не загубити.  

- [WoL Enable Service](https://github.com/dima101097/linux/tree/main/WoL_Enable) - Служба автоматично вмикає WoL в linux після увімкнення. Потрібно в випадку якщо самостійно це не відбувається 
```sh
    Зберігти WoL_Enable.sh в зручному місці, замінив ім'я інтрфейсу.
    Створити сервіс wol_enable.service за шляхом /lib/systemd/system/ та вказатишлях до sh скрипта.
    Віиконати sudo systemctl enable wol_enable.service 
 ```
___
- [Add user](https://github.com/dima101097/linux/blob/main/adduser.bash) - Скрипт для спрощення рутинних дій, створює нового користувача, дає права використання sudo, та для безпеки деактивовує root користувача.
```sh
    bash -c "$(wget -qLO - /tmp/adduser.bash https://raw.githubusercontent.com/dima101097/linux/refs/heads/main/adduser.bash)"
 ```   
