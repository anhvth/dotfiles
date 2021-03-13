while [ 1 ]
do
    echo "Test ssh"
    sleep 2
    sshpass -p tuongcuop123 ssh vnbot@101.99.36.174 -p 15722 -R 8887:localhost:8887 -R 6087:localhost:6087
done
