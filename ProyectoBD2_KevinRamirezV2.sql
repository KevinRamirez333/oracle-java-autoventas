--Kevin Daniel Ramirez Marin 2190-22-3594 Proyecto final Bases de datos II 

--06/05/2025
--Creacion de usuario
alter session set "_ORACLE_SCRIPT"= true;
create user examenfinal1 identified by e;
--Se le otorgan privilegios basicos
--Crear conexiones y resource permite crear objetos, vistas y procedimientos
grant connect, resource to examenfinal1;
--Privilegio de conectar a la base de datos y poder ceder permiso a otros usuarios
grant create session to examenfinal1 with admin option;
--Sin limite de almacenamiento para las tablas
grant unlimited tablespace to examenfinal1;
--Permite crear las tablas, debido a que resource ya no lo incorpora
grant create table to examenfinal;
--Creacion de usuarios
grant alter user, drop user to examenfinal1 with admin option;
grant create user to examenfinal1 with admin option;
--Permite crear roles
grant create role to examenfinal1 with admin option;
--CREACION DE TABLAS

--Tabla estado
create table estado (
    id_estado number(2) primary key,
    estado varchar2(20) not null
);

--Tabla marca
create table marca(
    id_marca number(3) primary key,
    nombre varchar2(30) not null
);

--Tabla vehiculo

create table vehiculo(
    vin varchar2(17) primary key,
    id_marca number(3) not null,
    placa varchar2(10),
    id_estado number(2) not null,
    modelo varchar2(30),
    anio number(4),
    color varchar2(20),
    precio_venta number(12,2),
    foreign key(id_marca) references marca(id_marca),
    foreign key(id_estado)references estado(id_estado)
);

--Tabla cliente
create table cliente(
    id_cliente number(6) primary key,
    nombre varchar2(50) not null, 
    dpi varchar2(20) unique,
    telefono varchar2(15),
    direccion varchar2(100)
);
--SE AGREGO NIT A LA TABLA CLIENTE
alter table cliente add (nit varchar2(20));

--Tabla importacion

create table importacion(
    id_importacion number(6) primary key,
    vin varchar2(17) not null, 
    fecha_importacion date,
    pais_origen varchar2(30),
    foreign key(vin) references vehiculo(vin)
);

--Tabla de importancioncostos (id_importacion es tanto pk y fk)
create table importacioncostos (
    id_importacion number(6) primary key,
    precioquetzal number(12,2),
    costotraidaquetzal number(12,2),
    impuestos number(12,2),
    tramites number(12,2),
    placas number(12,2),
    otrosgastos number(12,2),
    costototal number(12,2),
    foreign key(id_importacion)references importacion(id_importacion)
);

--Tabla venta
create table venta (
    id_venta number(6) primary key,
    vin varchar2(17) not null,
    id_cliente number(6) not null,
    fecha date,
    cuotas number(3), --Solamnente sera informativo
    tipo_pago varchar2(10), --'contado' o 'credito'
    foreign key (vin) references vehiculo(vin),
    foreign key (id_cliente) references cliente(id_cliente)
);

--Tabla ventacuotas
create table ventacuotas(
    id_cuota number(6) primary key,
    id_venta number(6) not null,
    fecha_pago date,
    monto number(12,2),
    interes number(5,2),
    estado varchar2(15), --'pagada' o 'pendiente'
    foreign key (id_venta) references venta(id_venta)
);

--07/05/2024
--Se insertaran datos para verificar el funcionamiento de las tablas (la integridad de las referencias)

--Tabla estado
insert into estado values (1,'Disponible');
insert into estado values (2,'Vendido');
insert into estado values (3, 'Reparacion');

--Tabla marca
insert into marca values (101,'Toyota');
insert into marca values (102,'Honda');

--Tabla vehiculo
insert into vehiculo (vin, id_marca, placa, id_estado, modelo, anio, color, precio_venta)
values ('JTDBR32E520123456', 101, 'P123ABC', 1, 'Corolla', 2020, 'Blanco', 85000.00);

insert into vehiculo (vin, id_marca, placa, id_estado, modelo, anio, color, precio_venta)
values ('VIN001', 101, 'P123ABC', 1, 'Corolla', 2020, 'Negro', 85000.00);


--Tabla cliente
insert into cliente (id_cliente, nombre, dpi, telefono, direccion)
values (100001,'Carlos Perez','123456789101','55551234','Zona 1, Guatemala');

--Tabla importacion
insert into importacion (id_importacion, vin, fecha_importacion)
values (50001,'JTDBR32E520123456', to_date('2024-01-15', 'yyyy-mm-dd'));


--Tabla importacioncostos
insert into importacioncostos (id_importacion, precioquetzal, costotraidaquetzal, impuestos, tramites, placas, otrosgastos, costototal)
values (50001, 70000.00, 3000.00, 5000.00, 1000.00, 800.00, 200.00, 80000.00);

--Tabla venta
insert into venta (id_venta, vin, id_cliente, fecha, cuotas, tipo_pago)
values (600001, 'JTDBR32E520123456', 100001, to_date('2024-02-01', 'yyyy-mm-dd'), 0, 'contado');
--En este ejemplo utilizamos venta al contado por lo cual no insertamos valores en ventacuotas.

insert into venta (id_venta, vin, id_cliente, fecha, cuotas, tipo_pago)
values (600002, 'VIN001', 100001, to_date('01-02-2024', 'dd-mm-yyyy'),12,'credito');

  
--CREACION DE PROCEDIMIENTOS LLENARCUOTAS
--EN BASE AL NUMERO DE CUOTAS
set serveroutput on;
create or replace procedure llenarcuotas(cod_vin varchar2) as 
    abono number;
    interes_porcentaje number(5,2);
    monto_final number(12,2);
    v_id_cuota number;
    v_id_venta number;
    fechaventa date;
    v_cuotas number;
    
begin
    --Traer datos de la venta asociada al VIN
    select id_venta, fecha, cuotas into v_id_venta,fechaventa, v_cuotas
    from venta where vin=cod_vin;
    
    --Calcular el abono base (sin intereses)
    select precio_venta/v_cuotas into abono from vehiculo where vin=cod_vin;
    
    --Determinar el interses segun las cuotas
    case v_cuotas
        when 6 then interes_porcentaje := 5;
        when 10 then interes_porcentaje := 10;
        when 12 then interes_porcentaje := 20;
        when 24 then interes_porcentaje := 20;
        else interes_porcentaje:=0;
    end case;
    
    --Inicializar id de cuota 
    select nvl(max(id_cuota),0)+1 into v_id_cuota from ventacuotas;
    
    --Generar cuotas
    for i in 1..v_cuotas loop 
        fechaventa := add_months(fechaventa,1); --suma un mes por cuota
        monto_final := abono +(abono*interes_porcentaje/100);
       
       insert into ventacuotas(id_cuota, id_venta, fecha_pago, monto, interes, estado)
       values (v_id_cuota,v_id_venta, fechaventa, monto_final, interes_porcentaje, 'pendiente');
       
       v_id_cuota := v_id_cuota + 1;
    end loop;
    
    commit;
    
    dbms_output.put_line ('Cuotas generadas correctamente');
end llenarcuotas;

--Ejemplo de funcionamiento de llenar cuotas

execute llenarcuotas ('VIN001');

--CALCULAR COSTOTOTAL DE VEHICULO

create or replace procedure costototalvehiculo (
    p_vin in varchar2, 
    p_ganancia_porcentaje in number 
) as
    v_precioquetzal importacioncostos.precioquetzal%type;
    v_costotraida importacioncostos.costotraidaquetzal%type;
    v_impuestos importacioncostos.impuestos%type;
    v_tramites importacioncostos.tramites%type;
    v_placas importacioncostos.placas%type;
    v_otrosgastos importacioncostos.otrosgastos%type;
    v_costototal importacioncostos.costototal%type;
    v_precio_venta vehiculo.precio_venta%type;
    v_id_importacion importacion.id_importacion%type;
    v_id_estado vehiculo.id_estado%type;
begin
    --Verificar estado
    select id_estado into v_id_estado from vehiculo where vin=p_vin;
    
    if v_id_estado = 3 then 
        --Obtener id de importacion
        select id_importacion into v_id_importacion from importacion where vin = p_vin;
        
        --Obtener costos
        select precioquetzal, costotraidaquetzal, impuestos, tramites, placas, otrosgastos
        into v_precioquetzal, v_costotraida, v_impuestos, v_tramites, v_placas, v_otrosgastos
        from importacioncostos where id_importacion = v_id_importacion;
        
        --Calcular costo total
        v_costototal := v_precioquetzal + v_costotraida + v_impuestos + v_tramites + v_placas + v_otrosgastos;
        
        --Actualizar costototal
        update importacioncostos set costototal = v_costototal where id_importacion = v_id_importacion;
        
        --Calcular precio de venta con porcentaje
        v_precio_venta := v_costototal * (1+(p_ganancia_porcentaje/100));
        
        --Actualizar vehiculo: estado disponible (2) y precio_venta
        update vehiculo set precio_venta = v_precio_venta, id_estado = 1 where vin = p_vin;
        
        dbms_output.put_line ('Costo total y precio de venta con ganancia del '|| p_ganancia_porcentaje||'% actualizados');
        commit;
    else
        dbms_output.put_line ('El vehiculo no esta en reparacion. No se puede calcular el costo total.');
    end if;
exception 
    when no_data_found then
        dbms_output.put_line ('Error: No se encontro el vehiculo o la importacion');
    when others then
        dbms_output.put_line ('Error inesperado '||sqlerrm);
end;
/
--Prueba de procedimiento a un costo total de un vehiculo mando el vin y el porcentaje de ganancia
execute costototalvehiculo('JTDBR32E520123456',60);


select * from importacioncostos where id_importacion='50001';

select * from vehiculo where vin = 'JTDBR32E520123456';
--08/05/2025
--PROCEDIMIENTO PARA INSERTAR EN TABLA IMPORTACIONCOSTOS, TAMBIEN SE CALCULA EL PRECIO EN DOLARES 
--Y LA TASA DE CAMBIO PARA SU CONVERSION EN PRECIOQUETZALES DEL VEHICULO

create or replace procedure insertar_costos_importacion (
--Parametros de entrada 
    p_vin in varchar2,
    p_precio_dolares in number,
    p_tasa_cambio in number,
    p_costotraidaquetzal in number,
    p_impuesto in number,
    p_tramites in number,
    p_placas in number,
    p_otrosgastos in number
) as
--Variables locales del procedimiento para realizar operaciones
    v_id_importacion importacion.id_importacion%type;
    v_precioquetzal number;
begin
    --Calcular el precio en quetzales
    v_precioquetzal := p_precio_dolares * p_tasa_cambio;
    
    --Obtener el id_importacion relacionado al vin
    select id_importacion into v_id_importacion from importacion where vin= p_vin;
    
    --Insertar los costos en la tabla importacioncostos
    insert into importacioncostos (
    id_importacion,
    precioquetzal,
    costotraidaquetzal,
    impuestos,
    tramites,
    placas,
    otrosgastos
    )
    values (
        v_id_importacion,
        v_precioquetzal,
        p_costotraidaquetzal,
        p_impuesto,
        p_tramites,
        p_placas,
        p_otrosgastos
    );


    dbms_output.put_line('Costos de importacion insertados correctamente. ');
    commit;
exception
    when no_data_found then 
        dbms_output.put_line('Error: No se encontro el VIN en la tabla de importaciones.');
    when others then
        dbms_output.put_line ('Error inesperado: '||sqlerrm);
end insertar_costos_importacion;
/

--PROCEDIMIENTO PARA REGISTRAR UNA VENTA
create or replace procedure registrar_venta(
    p_vin in venta.vin%type,
    p_id_cliente in venta.id_cliente%type,
    p_fecha in venta.fecha%type,
    p_cuotas in venta.cuotas%type,
    p_tipo_pago in venta.tipo_pago%type,
    p_id_venta out venta.id_venta%type
) as 
    v_nuevo_id venta.id_venta%type;
    v_existente number;
begin 
    -- Verificar si el vehículo ya tiene una venta
    select count(*) into v_existente
    from venta
    where vin = p_vin;

    if v_existente > 0 then
        raise_application_error(-20004, 'Este vehículo ya ha sido vendido.');
    end if;

    -- Validar tipo de pago
    if lower(p_tipo_pago) not in ('contado', 'credito') then
        raise_application_error(-20001, 'Tipo de pago inválido. Debe ser ''contado'' o ''credito''.');
    end if;

    -- Validar cuotas para crédito
    if lower(p_tipo_pago) = 'credito' and p_cuotas not in (6, 10, 12, 24) then
        raise_application_error(-20002, 'Número de cuotas inválido. Solo se permite 6, 10, 12 o 24 para crédito.');
    end if;

    -- Para contado, las cuotas deben ser 0
    if lower(p_tipo_pago) = 'contado' and p_cuotas != 0 then
        raise_application_error(-20003, 'Para pagos al contado, las cuotas deben ser 0.');
    end if;

    -- Generar nueva PK
    select nvl(max(id_venta), 0) + 1 into v_nuevo_id from venta;

    -- Insertar venta
    insert into venta (id_venta, vin, id_cliente, fecha, cuotas, tipo_pago)
    values (v_nuevo_id, p_vin, p_id_cliente, p_fecha, p_cuotas, p_tipo_pago);

    -- Generar cuotas si es crédito
    if lower(p_tipo_pago) = 'credito' then
        llenarcuotas(p_vin);
    end if;

    -- Confirmar transacción
    commit;

    -- Devolver ID de venta
    p_id_venta := v_nuevo_id;

    dbms_output.put_line('Venta creada con ID=' || v_nuevo_id);
exception
    when others then
        rollback;
        raise;
end registrar_venta;
/

--INSERTAR VEHICULO

create or replace procedure insertar_vehiculo(
    p_vin in vehiculo.vin%type,
    p_id_marca in vehiculo.id_marca%type,
    p_placa in vehiculo.placa%type,
    p_id_estado in vehiculo.id_estado%type,
    p_modelo in vehiculo.modelo%type,
    p_anio in vehiculo.anio%type,
    p_color in vehiculo.color%type
) as 
begin 
    insert into vehiculo (
        vin, id_marca, placa, id_estado, modelo, anio, color) 
    values (
        p_vin, p_id_marca, p_placa, p_id_estado,p_modelo, p_anio, p_color
    );
    dbms_output.put_line('Datos del vehiculo guardados correctamente');
exception
    when others then
        --Manejo simple de errores
        raise_application_error (-20001, 'Error al insertar vehiculo: '||sqlerrm);
end;
/

--PROCEDIMIENTO PARA OBTENER EL NOMBRE ESTADO
create or replace function obtener_nombre_estado (
    v_id_estado in estado.id_estado%type
) return varchar2
is
    v_nombre_estado estado.estado%type;
begin
    select estado into v_nombre_estado
    from estado
    where id_estado = v_id_estado;

    return v_nombre_estado;

exception
    when no_data_found then
        return 'estado no encontrado';
    when others then
        return 'error: ' || sqlerrm;
end;

--ELIMINAR VEHICULO
create or replace procedure eliminar_vehiculo_por_vin (
    p_vin in varchar2
)
is
begin
    -- eliminar de importacioncostos
    delete from importacioncostos
    where id_importacion in (
        select id_importacion from importacion where vin = p_vin
    );

    -- eliminar de importacion
    delete from importacion
    where vin = p_vin;

    -- eliminar de vehiculo
    delete from vehiculo
    where vin = p_vin;
    dbms_output.put_line('Vehiculo eliminado correctamente');
    commit; -- confirmar los cambios
exception
    when others then
        rollback;
        raise_application_error(-20001, 'error al eliminar el vehículo: ' || sqlerrm);
end;
/

--PROCEDIMIENTO PARA CONSULTAR VEHICULO POR VIN
create or replace procedure consultar_vehiculo_por_vin (
    p_vin          in  vehiculo.vin%type,
    p_id_marca     out vehiculo.id_marca%type,
    p_placa        out vehiculo.placa%type,
    p_id_estado    out vehiculo.id_estado%type,
    p_modelo       out vehiculo.modelo%type,
    p_anio         out vehiculo.anio%type,
    p_color        out vehiculo.color%type,
    p_precio_venta out vehiculo.precio_venta%type
)
is
begin
    select id_marca, placa, id_estado, modelo, anio, color, precio_venta
    into p_id_marca, p_placa, p_id_estado, p_modelo, p_anio, p_color, p_precio_venta
    from vehiculo
    where vin = p_vin;
exception
    when no_data_found then
        p_id_marca := null;
        p_placa := null;
        p_id_estado := null;
        p_modelo := null;
        p_anio := null;
        p_color := null;
        p_precio_venta := null;
    when others then
        raise_application_error(-20003, 'error al consultar vehículo: ' || sqlerrm);
end;
/
--ACTUALIZAR VEHICULO
create or replace procedure actualizar_vehiculo (
    p_vin          in vehiculo.vin%type,
    p_id_marca     in vehiculo.id_marca%type,
    p_placa        in vehiculo.placa%type,
    p_id_estado    in vehiculo.id_estado%type,
    p_modelo       in vehiculo.modelo%type,
    p_anio         in vehiculo.anio%type,
    p_color        in vehiculo.color%type
)
is
begin
    update vehiculo
    set id_marca  = p_id_marca,
        placa     = p_placa,
        id_estado = p_id_estado,
        modelo    = p_modelo,
        anio      = p_anio,
        color     = p_color
    where vin = p_vin;

    if sql%rowcount = 0 then
        raise_application_error(-20001, 'no se encontró el vehículo con vin ' || p_vin);
    end if;

    commit;
    dbms_output.put_line('vehículo actualizado correctamente.');
exception
    when others then
        rollback;
        raise_application_error(-20002, 'error al actualizar el vehículo: ' || sqlerrm);
end;
/

--PROCEDIMIENTO PARA CREAR CLIENTE
create or replace procedure crear_cliente (
    p_nombre in cliente.nombre%type,
    p_dpi in cliente.dpi%type,
    p_telefono in cliente.telefono%type,
    p_direccion in cliente.direccion%type,
    p_nit in cliente.nit%type
) as
    v_nuevo_id cliente.id_cliente%type;
begin
    select nvl(max(id_cliente),0) + 1 into v_nuevo_id from cliente;

    insert into cliente (id_cliente, nombre, dpi, telefono, direccion, nit)
    values (v_nuevo_id, p_nombre, p_dpi, p_telefono, p_direccion, p_nit);

    commit;
    dbms_output.put_line('cliente creado con id= ' || v_nuevo_id);
exception
    when dup_val_on_index then
        raise_application_error(-20010,'el dpi o nit ya existe');
    when others then
        rollback;
        raise;
end crear_cliente;
/

--CONSULTAR CLIENTE POR DPI
create or replace procedure consultar_cliente_por_dpi (
    p_dpi in cliente.dpi%type,
    p_id_cliente out cliente.id_cliente%type,
    p_nombre out cliente.nombre%type,
    p_telefono out cliente.telefono%type,
    p_direccion out cliente.direccion%type,
    p_nit out cliente.nit%type
) as
begin
    select id_cliente, nombre, telefono, direccion, nit
    into p_id_cliente, p_nombre, p_telefono, p_direccion, p_nit
    from cliente
    where dpi = p_dpi;
exception
    when no_data_found then
        p_id_cliente := null;
        p_nombre := null;
        p_telefono := null;
        p_direccion := null;
        p_nit := null;
end consultar_cliente_por_dpi;
/

--ACTUALIZAR CLIENTE POR IDCLIENTE
create or replace procedure actualizar_cliente (
    p_id_cliente in cliente.id_cliente%type,
    p_nombre     in cliente.nombre%type,
    p_telefono   in cliente.telefono%type,
    p_direccion  in cliente.direccion%type,
    p_nit        in cliente.nit%type
) as
begin
    update cliente
    set nombre = p_nombre,
        telefono = p_telefono,
        direccion = p_direccion,
        nit = p_nit
    where id_cliente = p_id_cliente;

    if sql%rowcount = 0 then
        raise_application_error(-20020, 'no se encontró el cliente con el id proporcionado.');
    end if;

    commit;
end actualizar_cliente;
/

--ELIMINAR CLIENTE POR IDCLIENTE
create or replace procedure eliminar_cliente (
    p_id_cliente in cliente.id_cliente%type
) as
begin
    delete from cliente
    where id_cliente = p_id_cliente;

    if sql%rowcount = 0 then
        raise_application_error(-20030, 'no se encontró el cliente con el id proporcionado.');
    end if;

    commit;
end eliminar_cliente;

--CREAR IMPORTACION
create or replace procedure crear_importacion (
    p_vin in vehiculo.vin%type,
    p_fecha_importacion in date,
    p_pais_origen in importacion.pais_origen%type
) as
    v_nuevo_id importacion.id_importacion%type;
    v_dummy number;
begin
    -- validar que el vin exista en la tabla vehiculo
    begin
        select 1 into v_dummy from vehiculo where vin = p_vin;
    exception
        when no_data_found then
            raise_application_error(-20040, 'el vin proporcionado no existe en la tabla vehiculo.');
    end;

    -- validar que no exista ya una importación con ese vin
    begin
        select 1 into v_dummy from importacion where vin = p_vin;
        raise_application_error(-20041, 'este vin ya tiene una importación registrada.');
    exception
        when no_data_found then
            null; -- no existe, se puede continuar
    end;

    -- generar nuevo id
    select nvl(max(id_importacion), 0) + 1 into v_nuevo_id from importacion;

    -- insertar datos
    insert into importacion (id_importacion, vin, fecha_importacion, pais_origen)
    values (v_nuevo_id, p_vin, p_fecha_importacion, p_pais_origen);

    commit;
end crear_importacion;
/

--CONSULTAR VEHICULO EN LA INTERFAZ DE CREAR IMPORTACION
--FROM DUAL: Se usa porque estamos haciendo una selección sin una tabla explícita (ya que usamos subconsultas)
create or replace procedure consultar_vehiculo_nombre (
    p_vin in vehiculo.vin%type,
    p_marca out varchar2,
    p_modelo out varchar2
) as
begin
    select 
        (select m.nombre from marca m 
         where m.id_marca = (select v.id_marca from vehiculo v where v.vin = p_vin)),
        (select v.modelo from vehiculo v where v.vin = p_vin)
    into p_marca, p_modelo
    from dual;
exception
    when no_data_found then
        p_marca := null;
        p_modelo := null;
end consultar_vehiculo_nombre;


--ACTUALIZAR IMPORTACION
create or replace procedure actualizar_importacion (
    p_id_importacion in importacion.id_importacion%type,
    p_fecha_importacion in importacion.fecha_importacion%type,
    p_pais_origen in importacion.pais_origen%type
) as
begin
    update importacion
    set fecha_importacion = p_fecha_importacion,
        pais_origen = p_pais_origen
    where id_importacion = p_id_importacion;

    if sql%rowcount = 0 then
        raise_application_error(-20050, 'no se encontró una importación con ese id.');
    end if;

    commit;
end actualizar_importacion;
/
--OBTENER DATOS DE IMPORTACION POR EL VIN EN INTERFAZ DE ELIMINAR Y ACTUALIZAR IMPORTACION
create or replace procedure obtener_importacion_por_vin (
    p_vin in vehiculo.vin%type,
    p_id out importacion.id_importacion%type,
    p_fecha out importacion.fecha_importacion%type,
    p_pais out importacion.pais_origen%type
) as
begin
    select id_importacion, fecha_importacion, pais_origen
    into p_id, p_fecha, p_pais
    from importacion
    where vin = p_vin;

exception
    when no_data_found then
        p_id := null;
        p_fecha := null;
        p_pais := null;
end obtener_importacion_por_vin;

--ELIMINAR IMPORTACION
create or replace procedure eliminar_importacion (
    p_id_importacion in importacion.id_importacion%type
) as
begin
    delete from importacion
    where id_importacion = p_id_importacion;

    if sql%rowcount = 0 then
        raise_application_error(-20051, 'no se encontró una importación con ese id.');
    end if;

    commit;
end eliminar_importacion;

--OBTENER ID IMPORTACION MEDIANTE EL VIN, ESTO EN LA INTERFAZ DE IMPORTACION COSTOS
create or replace procedure obtener_id_importacion_por_vin (
    p_vin in vehiculo.vin%type,
    p_id out importacion.id_importacion%type
) as
begin
    select id_importacion
    into p_id
    from importacion
    where vin = p_vin;

exception
    when no_data_found then
        p_id := null;
end obtener_id_importacion_por_vin;

--OBTENER ESTADO DEL VEHICULO (INTERFAZ DE IMPORTACIONCOSTOS, PARA EVITAR ERRORES)
create or replace function obtener_estado_vehiculo(p_vin varchar2) return number is
    v_estado vehiculo.id_estado%type;
begin
    select id_estado into v_estado from vehiculo where vin = p_vin;
    return v_estado;
exception
    when no_data_found then
        return null;
end obtener_estado_vehiculo;

--Obtener id importacion para la verificacion de la interfaz de importacion costos

create or replace function obtener_id_importacion(vin_in in varchar2) 
    return number
is
    v_id_importacion number;
begin
    -- Intentamos obtener el id_importacion basado en el vin
    select id_importacion
    into v_id_importacion
    from importacioncostos
    where id_importacion = (select id_importacion from importacion where vin = vin_in)
    and rownum = 1;  -- Aseguramos que solo se obtenga un registro

    return v_id_importacion; -- Si encontramos el id_importacion, lo retornamos
exception
    when no_data_found then
        return null;  -- Si no se encuentra, retornamos null
    when others then
        raise;  -- Lanzamos cualquier otro error
end obtener_id_importacion;

--PROCEDIMIENTO PARA OBTENER COSTOS IMPORTACION

create or replace procedure obtener_costos_importacion (
    p_id_importacion in number,
    p_precioquetzal out number,
    p_costotraidaquetzal out number,
    p_impuestos out number,
    p_tramites out number,
    p_placas out number,
    p_otrosgastos out number,
    p_costototal out number
) as
begin
    -- consultamos los datos de la tabla importacioncostos
    select precioquetzal, costotraidaquetzal, impuestos, tramites, placas, otrosgastos, costototal
    into p_precioquetzal, p_costotraidaquetzal, p_impuestos, p_tramites, p_placas, p_otrosgastos, p_costototal
    from importacioncostos
    where id_importacion = p_id_importacion;

exception
    when no_data_found then
        -- si no se encuentra el id_importacion en la tabla, lanzamos un error controlado
        p_precioquetzal := null;
        p_costotraidaquetzal := null;
        p_impuestos := null;
        p_tramites := null;
        p_placas := null;
        p_otrosgastos := null;
        p_costototal := null;
end;
/
--ELIMINAR COSTOS DE IMPORTACION POR EL ID_IMPORTACION
create or replace procedure eliminar_costos_importacion (
    p_id_importacion in number
) as
begin
    -- eliminar los costos de importación de la tabla importacioncostos según el id_importacion
    delete from importacioncostos
    where id_importacion = p_id_importacion;
    
    -- si deseas devolver una notificación o manejar errores, puedes hacerlo aquí
    commit;  -- asegúrate de hacer commit para confirmar los cambios en la base de datos.
    
    exception
    when no_data_found then
        -- si no se encuentra el id_importacion, puedes manejarlo de esta manera
        dbms_output.put_line('no se encontró el id_importacion.');
    when others then
        -- manejo de errores generales
        dbms_output.put_line('error inesperado: ' || sqlerrm);
end;
/

--PROCEDIMIENTO PARA OBTENER ID IMPORTACION EN LA INTERFAZ DE IMPORTACION COSTOS BOTON GUARDAR 

create or replace  procedure obtener_id_importacion(vin_in in varchar2, id_importacion_out out number) 
is
begin
    -- Intentamos obtener el id_importacion basado en el vin
    select id_importacion
    into id_importacion_out
    from importacion
    where id_importacion = (select id_importacion from importacion where vin = vin_in)
    and rownum = 1;  -- Aseguramos que solo se obtenga un registro

exception
    when no_data_found then
        id_importacion_out := null;  -- Si no se encuentra, asignamos null al parámetro de salida
    when others then
        raise;  -- Lanzamos cualquier otro error
end obtener_id_importacion;

--ACTUALIZAR COSTOS IMPORTACION 
create or replace procedure actualizar_costos_importacion (
    p_vin in varchar2,
    p_precio_dolares in number,
    p_tasa_cambio in number,
    p_costotraidaquetzal in number,
    p_impuesto in number,
    p_tramites in number,
    p_placas in number,
    p_otrosgastos in number
) as
    v_id_importacion importacion.id_importacion%type;
    v_precioquetzal number;
begin
    -- Calcular el precio en quetzales
    v_precioquetzal := p_precio_dolares * p_tasa_cambio;

    -- Obtener el id_importacion relacionado al vin
    select id_importacion into v_id_importacion from importacion where vin = p_vin;

    -- Actualizar los costos en la tabla importacioncostos
    update importacioncostos
    set 
        precioquetzal = v_precioquetzal,
        costotraidaquetzal = p_costotraidaquetzal,
        impuestos = p_impuesto,
        tramites = p_tramites,
        placas = p_placas,
        otrosgastos = p_otrosgastos
    where id_importacion = v_id_importacion;

    dbms_output.put_line('Costos de importación actualizados correctamente.');
    commit;

exception
    when no_data_found then 
        dbms_output.put_line('Error: No se encontró el VIN en la tabla de importaciones.');
    when others then
        dbms_output.put_line('Error inesperado: ' || sqlerrm);
end actualizar_costos_importacion;

--PROCEDIMIENTO PARA OBTENER DATOS EN BASE AL DPI, UTILIZADO EN LA INTERFAZ DE VENTAS
create or replace procedure obtener_cliente_por_dpi(
    p_dpi in cliente.dpi%type,
    p_id_cliente out cliente.id_cliente%type,
    p_nombre out cliente.nombre%type
)
is
begin
    select id_cliente, nombre
    into p_id_cliente, p_nombre
    from cliente
    where dpi = p_dpi;

exception
    when no_data_found then
        p_id_cliente := null;
        p_nombre := null;
end obtener_cliente_por_dpi;

--PROCEDIMIENTO PARA CONSULTAR CUOTAS DE UNA VENTA REALIZADA A CREDITO 

create or replace procedure consultar_cuotas_venta(
    p_id_venta in ventacuotas.id_venta%type,
    p_cursor out sys_refcursor
) as
begin
    open p_cursor for
    select id_cuota, fecha_pago, monto, interes, estado
    from ventacuotas
    where id_venta = p_id_venta
    order by fecha_pago;
end consultar_cuotas_venta;

--PROCEDIMIENTO PARA ACTUALIZAR EL ESTADO DE CUOTA INTERFAZ DE CUOTAS JAVA
create or replace procedure actualizar_estado_cuota(
    p_id_cuota in ventacuotas.id_cuota%type,
    p_estado in ventacuotas.estado%type
) as
begin
    update ventacuotas
    set estado = p_estado
    where id_cuota = p_id_cuota;

    commit;
end actualizar_estado_cuota;

--PROCEDIMIENTO PARA CREAR MARCA VEHICULO 
create or replace procedure insertar_marca_vehiculo(
    p_nombre in varchar2
    
) as
    p_id_marca marca.id_marca%type;
begin
    
    select nvl(max(id_marca), 0) + 1 into p_id_marca from marca;

    insert into marca (id_marca, nombre)
    values (p_id_marca, p_nombre);
end insertar_marca_vehiculo;
/

--FUNCION PARA CONSULTAR MARCA 
create or replace function obtener_nombre_marca (
    v_id_marca in marca.id_marca%type
) return varchar2
is
    v_nombre marca.nombre%type;
begin
    select nombre into v_nombre from marca where id_marca = v_id_marca;
    return v_nombre;
exception
    when no_data_found then
        return 'Marca no encontrada';
    when others then
        return 'Error: ' || SQLERRM;
end;
/

--PROCEDIMIENTO PARA ACTUALIZAR MARCA 
create or replace procedure actualizar_marca(
    p_id_marca in number,
    p_nombre in varchar2
) as
begin
    update marca
    set nombre = p_nombre
    where id_marca = p_id_marca;
    commit; --Confirmar cambios
end actualizar_marca;

--PROCEDIMIENTO PARA ELIMINAR MARCA 
create or replace procedure eliminar_marca(
    p_id_marca in number
) as
begin
    delete from marca
    where id_marca = p_id_marca;
    commit; --Confirmar cambios
end eliminar_marca;

--PROCEDIMIENTO PARA GENERAR NUEVO ID MARCA APARTIR DEL ID MAXIMO
create or replace function obtener_nuevo_id_marca return number as
    v_id number;
begin
    select nvl(max(id_marca), 0) + 1 into v_id from marca;
    return v_id;
end obtener_nuevo_id_marca;



--CREACION DE TRIGGERS

--TRIGGER PARA ACTUALIZAR EL ESTADO DEL VEHICULO CUANDO SEA UNA VENTA AL CONTADO

create or replace trigger trg_actualizar_estado_venta
after insert on venta
for each row
begin
    if lower(:new.tipo_pago) in ('contado', 'credito') then
        update vehiculo 
        set id_estado = 2
        where vin = :new.vin;
        -- esto solo se ve en sql developer, no en java
        dbms_output.put_line('estado del vehículo actualizado');
    end if;
end trg_actualizar_estado_venta;
/

--PROCEDIMIENTO PARA OBTENER EL MODELO Y PRECIO DE VENTA ATRAVES DEL VIN INTERFAZ DE VENTAS
create or replace procedure obtener_vehiculo_por_vin(
    p_vin in vehiculo.vin%type,
    p_modelo out vehiculo.modelo%type,
    p_precio out vehiculo.precio_venta%type
)
is
begin
    select modelo, precio_venta
    into p_modelo, p_precio
    from vehiculo
    where vin = p_vin;

exception
    when no_data_found then
        p_modelo := null;
        p_precio := null;
end obtener_vehiculo_por_vin;
/
--TRIGGER PARA PREVENIR VALORES NEGATIVOS EN COSTOS DE IMPORTACION
create or replace trigger trg_validar_costos_importacion
before insert or update on importacioncostos
for each row
begin
    if :new.precioquetzal < 0 or
       :new.costotraidaquetzal < 0 or
       :new.impuestos < 0 or
       :new.tramites < 0 or
       :new.placas < 0 or
       :new.otrosgastos < 0 then 
       RAISE_APPLICATION_ERROR(-20001, 'Los valores de costos no pueden ser negativos');
    end if;
end trg_validar_costos_importacion;
/

--FUNCION PARA OBTENER EL ESTADO DEL VEHICULO POR VIN

create or replace function obtener_estado_vehiculo (p_vin in varchar2)
return varchar2
is
    v_estado varchar2(20);
begin
    select estado into v_estado
    from estado
    where id_estado = ( --Se requiirio de una consulta anidad para poder determinar
    --el id_estado en base a la tabla vehiculo debido a que no se encontraba en la tabla estado
    select id_estado from vehiculo where vin=p_vin);
    
    return v_estado;
exception
    when no_data_found then
        return 'No encontrado';
    when others then
        return 'Error ' || sqlerrm;
end;

--CONTINUACION DE AVANCE 09/05/2025 
--Creacion de roles y usuarios que interctuan con las diferentes tablas

--1. Definir roles
create role rol_duenio;
create role rol_supervisor;
create role rol_vendedor;

--Consulta de roles
SELECT role FROM DBA_ROLES;


select role from DBA_ROLES where ORIGIN = 'PROYECTOBD';

--Crear usuarios
alter session set "_ORACLE_SCRIPT"= true;
create user duenio identified by duenio123;
create user supervisor identified by super123;
create user vendedor identified by vendedor123;

--Permitir conectarse a la base de datos
grant create session to duenio, supervisor, vendedor;

--Permisos directo de usuarios
grant select, insert, update, delete on proyectobd.estado to duenio;
grant select, insert, update, delete on proyectobd.marca to duenio;
grant select, insert, update, delete on proyectobd.vehiculo to duenio;
grant select, insert, update, delete on proyectobd.cliente to duenio;
grant select, insert, update, delete on proyectobd.importacion to duenio;
grant select, insert, update, delete on proyectobd.importacioncostos to duenio;
grant select, insert, update, delete on proyectobd.venta to duenio;
grant select, insert, update, delete on proyectobd.ventacuotas to duenio;

--Permisos para ROL_DUEÑO
grant select, insert, update, delete on estado to rol_duenio;
grant select, insert, update, delete on marca to rol_duenio;
grant select, insert, update, delete on vehiculo to rol_duenio;
grant select, insert, update, delete on cliente to rol_duenio;
grant select, insert, update, delete on importacion to rol_duenio;
grant select, insert, update, delete on importacioncostos to rol_duenio;
grant select, insert, update, delete on venta to rol_duenio;
grant select, insert, update, delete on ventacuotas to rol_duenio;

GRANT UPDATE ON vehiculo TO PROYECTOBD;
SELECT owner FROM all_triggers WHERE trigger_name = 'TRG_ACTUALIZAR_ESTADO_VENTA';
SELECT * FROM user_tab_privs WHERE table_name = 'VEHICULO';
SELECT trigger_name, status FROM user_triggers WHERE table_name = 'VENTA';
SELECT * FROM user_tab_privs WHERE table_name = 'VEHICULO';

grant execute on llenarcuotas to rol_duenio;
grant execute on costototalvehiculo to rol_duenio;
grant execute on insertar_costos_importacion to rol_duenio;
grant execute on obtener_estado_vehiculo to rol_duenio;
grant execute on crear_cliente to rol_duenio;
grant execute on registrar_venta to rol_duenio;
grant execute on obtener_nombre_marca to rol_duenio;
--Permisos de ejecutar directamente al usuario y no al rol (24 procedimientos)
grant execute on proyectobd.obtener_nombre_estado to duenio; --Funcion
grant execute on proyectobd.insertar_vehiculo to duenio;
grant execute on proyectobd.eliminar_vehiculo_por_vin to duenio;
grant execute on proyectobd.actualizar_vehiculo to duenio;  
GRANT EXECUTE ON obtener_nombre_marca TO duenio; --Funcion
GRANT EXECUTE ON consultar_vehiculo_por_vin TO duenio;
grant execute on proyectobd.consultar_cliente_por_dpi to duenio;
grant execute on proyectobd.actualizar_cliente to duenio;
grant execute on proyectobd.eliminar_cliente to duenio;
grant execute on proyectobd.crear_importacion to duenio;
grant execute on proyectobd.consultar_vehiculo_nombre to duenio;
grant execute on proyectobd.obtener_importacion_por_vin to duenio;
grant execute on proyectobd.actualizar_importacion to duenio;
grant execute on proyectobd.eliminar_importacion to duenio;
grant execute on proyectobd.obtener_id_importacion_por_vin to duenio;
grant execute on proyectobd.obtener_estado_vehiculo to duenio; --Funcion
grant execute on proyectobd.obtener_id_importacion to duenio;
grant execute on proyectobd.obtener_costos_importacion to duenio;
grant execute on proyectobd.eliminar_costos_importacion to duenio;
grant execute on proyectobd.obtener_id_importacion to duenio;
grant execute on proyectobd.actualizar_costos_importacion to duenio;
grant execute on proyectobd.obtener_cliente_por_dpi to duenio;
grant execute on proyectobd.obtener_vehiculo_por_vin to duenio;
grant execute on proyectobd.registrar_venta to duenio;
grant execute on proyectobd.llenarcuotas to duenio;
grant execute on proyectobd.consultar_cuotas_venta to duenio;
grant execute on proyectobd.actualizar_estado_cuota to duenio;

grant execute on proyectobd.insertar_marca_vehiculo to duenio;
grant execute on proyectobd.obtener_nombre_marca to duenio;
grant execute on proyectobd.actualizar_marca to duenio;
grant execute on proyectobd.eliminar_marca to duenio;
grant execute on proyectobd.obtener_nuevo_id_marca to duenio;

--PERMISOS PARA EJECUCION DE TRIGGERS

GRANT CREATE ANY TRIGGER TO rol_duenio;
GRANT ALTER ANY TRIGGER TO rol_duenio;


--Consulta para verificar la creacion de la funcion obtener_nombre_marca
SELECT object_name, owner 
FROM all_objects 
WHERE object_type = 'FUNCTION' AND object_name = 'OBTENER_NOMBRE_MARCA';

--Permisos para rol_supervisor
grant select, insert, update, delete on vehiculo to rol_supervisor;
grant select, insert, update, delete on cliente to rol_supervisor;
grant select, insert, update, delete on importacion to rol_supervisor;
grant select, insert, update, delete on importacioncostos to rol_supervisor;
grant select, insert, update, delete on venta to rol_supervisor;
grant select, insert, update, delete on ventacuotas to rol_supervisor;
grant execute on llenarcuotas to rol_supervisor;
grant execute on costototalvehiculo to rol_supervisor;
grant execute on insertar_costos_importacion to rol_supervisor;
grant execute on registrar_venta to rol_supervisor;
grant execute on crear_cliente to rol_supervisor;

--Otorgar permisos directamente al usuario (supervisor) y no al rol
grant execute on proyectobd.obtener_nombre_estado to supervisor;
grant execute on proyectobd.insertar_vehiculo to supervisor;
grant execute on proyectobd.eliminar_vehiculo_por_vin to supervisor;
grant execute on proyectobd.actualizar_vehiculo to supervisor;
grant execute on obtener_nombre_marca to supervisor;
grant execute on consultar_vehiculo_por_vin to supervisor;
grant execute on proyectobd.consultar_cliente_por_dpi to supervisor;
grant execute on proyectobd.actualizar_cliente to supervisor;
grant execute on proyectobd.eliminar_cliente to supervisor;
grant execute on proyectobd.crear_importacion to supervisor;
grant execute on proyectobd.consultar_vehiculo_nombre to supervisor;
grant execute on proyectobd.obtener_importacion_por_vin to supervisor;
grant execute on proyectobd.actualizar_importacion to supervisor;
grant execute on proyectobd.eliminar_importacion to supervisor;
grant execute on proyectobd.obtener_id_importacion_por_vin to supervisor;
grant execute on proyectobd.obtener_estado_vehiculo to supervisor;
grant execute on proyectobd.obtener_id_importacion to supervisor;
grant execute on proyectobd.obtener_costos_importacion to supervisor;
grant execute on proyectobd.eliminar_costos_importacion to supervisor;
grant execute on proyectobd.obtener_id_importacion to supervisor;
grant execute on proyectobd.actualizar_costos_importacion to supervisor;
grant execute on proyectobd.obtener_cliente_por_dpi to supervisor;
grant execute on proyectobd.obtener_vehiculo_por_vin to supervisor;
grant execute on proyectobd.registrar_venta to supervisor;
grant execute on proyectobd.llenarcuotas to supervisor;
grant execute on proyectobd.consultar_cuotas_venta to supervisor;
grant execute on proyectobd.actualizar_estado_cuota to supervisor;

--Permisos para rol_vendedor (contado y credito)
grant select on vehiculo to rol_vendedor;
grant select, insert, update on cliente to rol_vendedor;
grant insert, update, select on venta to rol_vendedor;
grant insert, update, select on ventacuotas to rol_vendedor;
grant execute on registrar_venta to rol_vendedor;
grant execute on llenarcuotas to rol_vendedor; 
grant execute on crear_cliente to rol_vendedor;


--Otorgar permisos directamente al usuario (vendedor) y no al rol
--INTERFAZ VEHICULOS
grant execute on proyectobd.obtener_nombre_marca to vendedor;
grant execute on proyectobd.obtener_nombre_estado to vendedor;
grant execute on proyectobd.consultar_vehiculo_por_vin to vendedor;

--PERMISOS DE PROCEDIMIENTOS PARA MANEJAR LA INTERFAZ DE CLIENTES
grant execute on proyectobd.crear_cliente to vendedor;
grant execute on proyectobd.consultar_cliente_por_dpi to vendedor;
grant execute on proyectobd.actualizar_cliente to vendedor;
grant execute on proyectobd.eliminar_cliente to vendedor;

--PERMISOS DE PROCEDIMIENTOS PARA MANEJAR LA INTERFAZ DE VENTAS
grant execute on proyectobd.obtener_cliente_por_dpi to vendedor;
grant execute on proyectobd.obtener_vehiculo_por_vin to vendedor;
grant execute on proyectobd.registrar_venta to vendedor;
grant execute on proyectobd.consultar_cuotas_venta to vendedor;
grant execute on proyectobd.actualizar_estado_cuota to vendedor;
grant execute on proyectobd.llenarcuotas to vendedor; 


--Asignar roles a usuarios
grant ROL_DUENIO to duenio;
grant ROL_SUPERVISOR to supervisor;
grant ROL_VENDEDOR to vendedor;


