use std::collections::HashMap;
use std::error::Error;
use std::fmt;
use std::num::ParseIntError;

struct User {
    name: String,
    manager_id: Option<u32>,
}

fn find_user(users: &HashMap<u32, User>, id: u32) -> Option<&User> {
    users.get(&id)
}

// `?` on Option: return None as soon as one step is missing
fn manager_name(users: &HashMap<u32, User>, id: u32) -> Option<&str> {
    let user = find_user(users, id)?;
    let manager = find_user(users, user.manager_id?)?;
    Some(&manager.name)
}

// `?` on Result: propagate the error to the caller
fn sum_csv(line: &str) -> Result<i32, ParseIntError> {
    let mut total = 0;
    for field in line.split(',') {
        total += field.trim().parse::<i32>()?;
    }
    Ok(total)
}

// A domain error type
#[derive(Debug)]
enum ConfigError {
    Missing(&'static str),
    BadNumber {
        key: &'static str,
        source: ParseIntError,
    },
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            ConfigError::Missing(key) => write!(f, "missing key `{key}`"),
            ConfigError::BadNumber { key, source } => {
                write!(f, "`{key}` is not a number: {source}")
            }
        }
    }
}

impl Error for ConfigError {}

fn read_port(config: &HashMap<&str, &str>) -> Result<u16, ConfigError> {
    let raw = config.get("port").ok_or(ConfigError::Missing("port"))?;
    raw.parse::<u16>().map_err(|source| ConfigError::BadNumber {
        key: "port",
        source,
    })
}

// main can return a Result: an Err is printed and the exit code is 1
fn main() -> Result<(), Box<dyn Error>> {
    let mut users = HashMap::new();
    users.insert(
        1,
        User {
            name: "Grace".into(),
            manager_id: None,
        },
    );
    users.insert(
        2,
        User {
            name: "Ada".into(),
            manager_id: Some(1),
        },
    );

    println!("manager of 2: {:?}", manager_name(&users, 2));
    println!("manager of 1: {:?}", manager_name(&users, 1));
    println!("manager of 9: {:?}", manager_name(&users, 9));

    // Option combinators
    let name_len = find_user(&users, 2).map(|u| u.name.len()).unwrap_or(0);
    println!("name length: {name_len}");

    match find_user(&users, 3) {
        Some(user) => println!("found {}", user.name),
        None => println!("no user 3"),
    }

    println!("{:?}", sum_csv("1, 2, 3"));
    println!("{:?}", sum_csv("1, two, 3"));

    if let Err(e) = sum_csv("4, x") {
        println!("error: {e}");
    }

    let mut config = HashMap::new();
    println!("{:?}", read_port(&config).map_err(|e| e.to_string()));
    config.insert("port", "http");
    println!("{:?}", read_port(&config).map_err(|e| e.to_string()));
    config.insert("port", "3000");
    println!("{:?}", read_port(&config));

    // `?` converts ConfigError into Box<dyn Error> automatically
    let port = read_port(&config)?;
    println!("listening on {port}");
    Ok(())
}
