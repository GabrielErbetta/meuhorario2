# MeuHorario 2

MeuHorario 2 is a remake of the class enrollment simulator MeuHorario and is meant to help students of the Universidade Federal da Bahia to plan which classes they will attend every semester.

The original MeuHorario was built by Rodrigo Rocha in 2004 and can be accessed in http://meuhorario.dcc.ufba.br/.

### Dependencies and Running

  - `docker`
  - `docker-compose`

Just build the containers, `up` them and access `http://localhost:3000`.
For populating the database just run the take task `scraper:all`. That runs all the scrape tasks needed.
If you want, you can run the tasks manually so you can skip `scraper:discipline_infos` as it is the slowest and only provides the load in hours of the disciplines.

---

If you need anything, just create an issue to get in touch. 😉
