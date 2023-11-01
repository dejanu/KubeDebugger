
PATH=:$PATH:

PATH=${PATH//:\/Applications\/Visual Studio Code.app\/Contents\/Resources\/app\/bin:/:}

PATH=${PATH#:}; PATH=${PATH%:}
