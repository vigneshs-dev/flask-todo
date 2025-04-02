USE flask_todo_db;

CREATE TABLE IF NOT EXISTS flask_todo_db.todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task VARCHAR(200) NOT NULL
);
