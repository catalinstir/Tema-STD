package com.chat;

import java.io.*;
import java.util.*;
import javax.websocket.*;
import javax.websocket.server.*;
import java.sql.*;
import org.json.*;

@ServerEndpoint("/chat")
public class WebSocketChatServer {
    private static final Set<Session> sessions = Collections.synchronizedSet(new HashSet<>());
    
    // Updated DB connection info for Kubernetes environment
    // These will be overridden by environment variables in Kubernetes
    private static String DB_URL = "jdbc:mysql://chat-mysql:3306/chat";
    private static String DB_USER = "chatuser";
    private static String DB_PASSWORD = "chatpassword";
    
    static {
        // Check for environment variables and override defaults if present
        String envDbHost = System.getenv("DB_HOST");
        String envDbUser = System.getenv("DB_USER");
        String envDbPassword = System.getenv("DB_PASSWORD");
        
        if (envDbHost != null && !envDbHost.isEmpty()) {
            DB_URL = "jdbc:mysql://" + envDbHost + ":3306/chat";
        }
        
        if (envDbUser != null && !envDbUser.isEmpty()) {
            DB_USER = envDbUser;
        }
        
        if (envDbPassword != null && !envDbPassword.isEmpty()) {
            DB_PASSWORD = envDbPassword;
        }
        
        // Register JDBC driver
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("MySQL JDBC Driver registered successfully");
        } catch (ClassNotFoundException e) {
            System.err.println("Error loading MySQL JDBC driver: " + e.getMessage());
        }
    }
    
    @OnOpen
    public void onOpen(Session session) {
        sessions.add(session);
        System.out.println("New WebSocket connection established. Total connections: " + sessions.size());
        try {
            // Send chat history to new user
            Connection conn = null;
            PreparedStatement stmt = null;
            ResultSet rs = null;
            
            try {
                conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                String sql = "SELECT username, message, timestamp FROM messages ORDER BY timestamp DESC LIMIT 50";
                stmt = conn.prepareStatement(sql);
                rs = stmt.executeQuery();
                
                List<JSONObject> messageHistory = new ArrayList<>();
                
                while (rs.next()) {
                    String username = rs.getString("username");
                    String message = rs.getString("message");
                    String timestamp = rs.getString("timestamp");
                    
                    JSONObject msgJson = new JSONObject();
                    msgJson.put("username", username);
                    msgJson.put("message", message);
                    msgJson.put("timestamp", timestamp);
                    
                    messageHistory.add(msgJson);
                }
                
                // Reverse the list to get chronological order
                Collections.reverse(messageHistory);
                
                // Send each message
                for (JSONObject msg : messageHistory) {
                    session.getBasicRemote().sendText(msg.toString());
                }
            } finally {
                // Clean up resources
                if (rs != null) try { rs.close(); } catch (SQLException e) { /* ignore */ }
                if (stmt != null) try { stmt.close(); } catch (SQLException e) { /* ignore */ }
                if (conn != null) try { conn.close(); } catch (SQLException e) { /* ignore */ }
            }
        } catch (Exception e) {
            System.err.println("Error sending chat history: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    @OnMessage
    public void onMessage(String message, Session session) {
        try {
            // Parse message JSON
            JSONObject jsonMsg = new JSONObject(message);
            String username = jsonMsg.getString("username");
            String text = jsonMsg.getString("message");
            String timestamp = jsonMsg.getString("timestamp");
            
            Connection conn = null;
            PreparedStatement stmt = null;
            
            try {
                // Save to database
                conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                String sql = "INSERT INTO messages (username, message, timestamp) VALUES (?, ?, ?)";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, username);
                stmt.setString(2, text);
                stmt.setString(3, timestamp);
                stmt.executeUpdate();
            } finally {
                // Clean up resources
                if (stmt != null) try { stmt.close(); } catch (SQLException e) { /* ignore */ }
                if (conn != null) try { conn.close(); } catch (SQLException e) { /* ignore */ }
            }
            
            // Broadcast message to all connected clients
            for (Session s : sessions) {
                s.getBasicRemote().sendText(message);
            }
        } catch (Exception e) {
            System.err.println("Error processing message: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    @OnClose
    public void onClose(Session session) {
        sessions.remove(session);
        System.out.println("WebSocket connection closed. Remaining connections: " + sessions.size());
    }
    
    @OnError
    public void onError(Session session, Throwable throwable) {
        System.err.println("WebSocket error: " + throwable.getMessage());
        sessions.remove(session);
    }
}
