# DB notes:

- Generally speaking, we use migration files to create/update tables.
- Generally speaking, we use sequelize ORM to interact with the DB.
- Never write complex SQL queries unless the user specifically asked/inferred it. Prefer extracting logic to actual service code.
- Always start small; fewer columns are better. We can add more as we discover a need for them. No need to try to predict everything from the get-go.
