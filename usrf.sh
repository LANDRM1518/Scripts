#!/bin/bash

ayuda() {
    echo "+++++ MANUAL +++++"
    echo "./usuarios.sh"
    echo "Sirve para crear usuarios de manera personalizada:"
}

echo_error() {
    echo "$1" >&2
}

reportar_error() {
    local mensaje="$1"
    echo_error "$mensaje"
    ayuda
    exit 1
}

test "$1" == "-h" || test "$1" == "--help" && { ayuda; exit; }

validar_contra() {
    local contra="$1"
    if [[ ${#contra} -lt 8 ]]; then
        echo_error "La contraseña debe tener al menos 8 caracteres."
        return 1
    fi
    if ! [[ "$contra" =~ [A-Za-z] ]]; then
        echo_error "La contraseña debe contener al menos una letra."
        return 1
    fi
    if ! [[ "$contra" =~ [0-9] ]]; then
        echo_error "La contraseña debe contener al menos un número."
        return 1
    fi
    if ! [[ "$contra" =~ [@\%\^] ]]; then
        echo_error "La contraseña debe contener al menos un símbolo de estos (@, %, ^)."
        return 1
    fi
    return 0
}

crearcontra() {
    local usuario="$1"
    local contra

    while true; do
        echo "Ingresa la contraseña para el usuario:"
        read -s contra

        if validar_contra "$contra"; then
            echo "$usuario:$contra" | sudo chpasswd
            if [[ $? -eq 0 ]]; then
                echo "Contraseña establecida correctamente."
            else
                echo_error "Error al establecer la contraseña."
            fi
            return
        else
            echo_error "La contraseña no cumple con los requisitos. Intenta nuevamente."
        fi
    done
}

crear_usuario() {
    local grupo="$1"
    local nombre="$2"
    local usuario="$3"
    local dirhogar="$4"

    if getent passwd "$usuario" >/dev/null; then
        echo_error "El usuario '$usuario' ya existe."
        return 1
    fi

    useradd -g "$grupo" -c "$nombre" -m -d "$dirhogar" -s "/bin/bash" "$usuario"
    return $?
}

agregarusr() {
    local grupo
    local nombre
    local usuario
    local dirhogar

    clear
    echo "PROCESO PARA AGREGAR USUARIO...."
    sleep 1
    echo "Ingresa el nombre completo del usuario:"
    read nombre
    echo "Ingresa el nombre de usuario (username):"
    read usuario
    echo "Ingresa el grupo al que pertenecerá el usuario:"
    read grupo
    if ! getent group "$grupo" >/dev/null; then
        groupadd "$grupo"
        echo "Grupo '$grupo' creado."
    fi
    echo "Ingresa el directorio home del usuario:"
    read dirhogar

    if crear_usuario "$grupo" "$nombre" "$usuario" "$dirhogar"; then
        echo "Usuario '$usuario' creado correctamente."
        crearcontra "$usuario"
    else
        echo_error "Error al crear el usuario."
    fi
}

editarusr() {
    clear
    echo "ENTRANDO EN MODO CONFIGURACIÓN DE USUARIOS..."
    sleep 1
    local usr 
    echo "Ingresa el usuario al que quieres hacer cambios:"
    read usr
    grep -q "^$usr:" /etc/passwd || { echo "Error: Usuario No Encontrado"; exit 1; }

    select opt in "Cambiar Nombre Usuario" "Cambiar Grupo al usuario" "Cambiar Nombre completo de Usuario" "Cambiar shell de usuario" "Cambiar contraseña de usuario"; do
        if [ "$opt" = "Cambiar Nombre Usuario" ]; then
            local nombre
            echo "Ingrese el nuevo nombre:"
            read nombre
            sudo usermod -l "$nombre" "$usr"
            exit
        elif [ "$opt" = "Cambiar Grupo al usuario" ]; then
            local gru
            echo "Ingrese el nuevo grupo:"
            read gru
            sudo usermod -g "$gru" "$usr"
            exit
        elif [ "$opt" = "Cambiar Nombre completo de Usuario" ]; then
            local usname
            echo "Ingresa el nuevo nombre de usuario (nombre completo):"
            read usname
            sudo chfn -f "$usname" "$usr"
            exit
        elif [ "$opt" = "Cambiar shell de usuario" ]; then
            local sh
            echo "Ingresa el nuevo shell del usuario:"
            read sh
            sudo chsh -s "$sh" "$usr"
            exit
        elif [ "$opt" = "Cambiar contraseña de usuario" ]; then
            crearcontra "$usr"
            exit
        else
            echo "Opción no disponible."
            exit
        fi
    done
}

eliminarusr() {
	local us
	echo "Ingrese el usuario que quiere eliminar:"
	read us
	grep -q "$us" /etc/passwd && userdel -r "$us" 2>/dev/null && echo "Usuario $us eliminado correctamente." || echo "El usuario no existe."

}

edq() {
	clear
	echo "ENTRANDO MODO QUOTAS..."
	local qusr
	local lsoft
	local lhard
	local lsid
	local lhid
	echo "Ingresa al usuario que le quiere cambiar las quotas:"
	read qusr
	grep  -q "$qusr" <(sudo repquota -a)||{ echo "Error: Usuario No Encontrado"; exit 1; }
	echo "Define Limite SOFT (Si no quiere hacer cambios escriba 0):"
	read lsoft
	echo "Define Limite HARD (Si no quiere hacer cambios escriba 0):"
	read lhard
	echo "Define Limite SOFT de INODOS (Si no quiere modifcar escribir 0):"
	read lsid
	echo "Define Limite HARD de INODOS (Si no quiere modificar escrbir 0):"
	read lhid
	sudo setquota -u "$qusr" "$lsoft" "$lhard" "$lsid" "$lhid" /dev/sda1
	echo "Sus datos son:"
	sudo quota -u "$qusr"
}

asper() {
	clear
	local asperusr
	echo "Entrando en Seccion de permisos..."
	echo "A que usuario desea asignar permisos:"
	read asperusr
	grep -q "$asperusr" /etc/passwd || { echo "Error: Usuario No Encontrado"; exit 1; }
	select opt in "Asignar Permiso SUDO" "Asignar SUDO pero con LIMITACIONES"; do
	    if [ "$opt" = "Asignar Permiso SUDO" ]; then
		local r
		echo "Asignando permisos sudo a usuario..."
		sleep 2
		echo "Desea pedir contraseña al momento de usar sudo ?(si/no)"
		read r
		test "$r" == "si" && echo "$asperusr ALL=(ALL) ALL" | sudo tee -a /etc/sudoers || echo "$asperusr ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers 
	        exit
	    elif [ "$opt" = "Asignar SUDO pero con LIMITACIONES" ]; then
		local permisos
		local rr
		echo "Ingresa las direcciones de comandos que desea permitir:"
		echo "Escrbir los comandos separados por (,)  y direccion completa"
		echo  "ejemplo: /usr/bin/ls, /usr/bin/reboot ..."
		read permisos 
		echo "$Desea pedir contraseña al momento de usar sudo ?(si/no)"
                read rr
                test "$rr" == "si" && echo "$asperusr ALL=(ALL) $permisos" | sudo tee -a /etc/sudoers || echo "$asperusr ALL=(ALL) NOPASSWD: $permisos" | sudo tee -a /etc/sudoers
	        exit
	    else
        	echo "Opcion No valida"
	        exit
	    fi
	done
}

echo "------ Menú ------"
select opt in "Crear Usuario" "Editar Usuario" "Eliminar Usuario" "Editar Quotas" "Editar Permisos"; do
    if [ "$opt" = "Crear Usuario" ]; then
        agregarusr
        exit
    elif [ "$opt" = "Editar Usuario" ]; then
        editarusr
        exit
    elif [ "$opt" = "Eliminar Usuario" ]; then
        eliminarusr
        exit
    elif [ "$opt" = "Editar Quotas" ]; then
	edq
        exit
    elif [ "$opt" = "Editar Permisos" ]; then
        asper
        exit

    else
        echo "No Disponible por el momento"
        exit
    fi
done
