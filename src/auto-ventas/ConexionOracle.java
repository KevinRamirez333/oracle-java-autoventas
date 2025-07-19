/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package autoventasbd2kevinramirez;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 *
 * @author kevin
 */
public class ConexionOracle {
    public static Connection conectarComo(String usuario, String contrasena) throws SQLException {
        String url = "jdbc:oracle:thin:@localhost:1521:xe"; 
        return DriverManager.getConnection(url, usuario, contrasena);
    }
    
}
