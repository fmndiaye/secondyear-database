DROP TABLE IF EXISTS Sports CASCADE;
DROP TABLE IF EXISTS Pays CASCADE;
DROP TABLE IF EXISTS Equipes CASCADE;
DROP TABLE IF EXISTS Athletes CASCADE;
DROP TABLE IF EXISTS Epreuves CASCADE;
DROP TABLE IF EXISTS Medailles CASCADE;
DROP TABLE IF EXISTS Lieux CASCADE;
DROP TABLE IF EXISTS Matchs CASCADE;
DROP TABLE IF EXISTS Resultats CASCADE;

CREATE TABLE Sports(
	sid SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL,
	individuel BOOLEAN NOT NULL
	-- si individuel = TRUE, alors c'est un sport individuel, FALSE sinon
);

\copy Sports(nom, individuel) from 'Sports.txt' with (format csv, header);

CREATE TABLE Pays(
	pid SERIAL PRIMARY KEY,
	nom VARCHAR(30),
	continent VARCHAR(30)
);

\copy Pays(nom, continent) from 'Pays.txt' with (format csv, header);

CREATE TABLE Equipes(
	eid SERIAL PRIMARY KEY,
	nom VARCHAR(30) NOT NULL,
	nationalite INTEGER NOT NULL,
	sexe VARCHAR(30) NOT NULL,
	domaine INTEGER NOT NULL,
	FOREIGN KEY (nationalite) REFERENCES Pays(pid),
	FOREIGN KEY (domaine) REFERENCES Sports(sid)
);

\copy Equipes(nom, nationalite, sexe, domaine) from 'Equipes.txt' with(format csv, header);

CREATE TABLE Athletes(
	aid SERIAL PRIMARY KEY,
	prenom VARCHAR(100) NOT NULL,
	nom VARCHAR(100) NOT NULL,
	naissance DATE NOT NULL,
	nationalite INTEGER NOT NULL,
	sexe VARCHAR(30) NOT NULL,
	domaine INTEGER NOT NULL,
	equipe INTEGER,
	FOREIGN KEY (nationalite) REFERENCES Pays(pid),
	FOREIGN KEY (equipe) REFERENCES Equipes(eid),
	FOREIGN KEY (domaine) REFERENCES Sports(sid)
);

\copy Athletes(prenom, nom, naissance, nationalite, sexe, domaine, equipe) from 'Athletes.txt' with(format csv, header);
	
CREATE TABLE Epreuves(
	epid SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL,
	type INTEGER NOT NULL,
	sexe TEXT NOT NULL,
	FOREIGN KEY (type) REFERENCES Sports(sid)
);

\copy Epreuves(nom, type, sexe) from 'Epreuves.txt' with (format csv, header);

CREATE TABLE Medailles(
	mid SERIAL PRIMARY KEY,
	type VARCHAR(30) NOT NULL,
	epreuve INTEGER NOT NULL,
	gagnant INTEGER,
	equipegagnante INTEGER, 
	FOREIGN KEY (epreuve) REFERENCES Epreuves(epid),
	FOREIGN KEY (gagnant) REFERENCES Athletes(aid),
	FOREIGN KEY (equipegagnante) REFERENCES Equipes(eid)
);

\copy Medailles(type, epreuve, gagnant, equipegagnante) from 'Medailles.txt' with (format csv, header);

--partie 4
CREATE TABLE Lieux(
	lid SERIAL PRIMARY KEY,
	nom VARCHAR(30),
	indice INTEGER
);

\copy Lieux(nom, indice) from 'Lieux.txt' with (format csv, header);

CREATE TABLE Matchs(
	maid SERIAL PRIMARY KEY,
	nom VARCHAR(100),
	epreuve INTEGER NOT NULL,
	dates DATE NOT NULL,
	tour BOOLEAN NOT NULL,
	--si c'est un tour final (les gagnant obtiennent une medaille), tour vaut TRUE, FALSE sinon
	lieu INTEGER NOT NULL,
	FOREIGN KEY (epreuve) REFERENCES Epreuves(epid),
	FOREIGN KEY (lieu) REFERENCES Lieux(lid)
);

\copy Matchs(nom, epreuve, dates, tour, lieu) from 'Matchs.txt' with (format csv, header);

CREATE TABLE Resultats(
	paid SERIAL PRIMARY KEY,
	match INTEGER NOT NULL,
	participant INTEGER,
	equipepart INTEGER,
	temps TIME,
	score INTEGER,
	FOREIGN KEY (participant) REFERENCES Athletes(aid),
	FOREIGN KEY (equipepart) REFERENCES Equipes(eid)
);

\copy Resultats(match, participant, equipepart, temps, score) from 'Resultats.txt' with (format csv, header);

--Requetes
--Difficulté 1

--1
SELECT prenom, Athletes.nom
FROM Athletes, Medailles, Pays
WHERE Athletes.nationalite = Pays.pid AND Pays.nom = 'Italie' AND Medailles.gagnant = Athletes.aid;

--2
SELECT Epreuves.nom, Athletes.prenom, Athletes.nom, Pays.nom, Medailles.type
FROM Epreuves, Athletes, Pays, Medailles
WHERE (Medailles.epreuve = Epreuves.epid AND Medailles.gagnant = Athletes.aid AND (Epreuves.nom = '100MH' OR Epreuves.nom = '100MF') AND Athletes.nationalite = Pays.pid) 
OR (Medailles.epreuve = Epreuves.epid AND medailles.gagnant = Athletes.aid AND (Epreuves.nom = '200MH' OR Epreuves.nom = '200MF') AND Athletes.nationalite = Pays.pid) 
OR (Medailles.epreuve = Epreuves.epid AND Medailles.gagnant = Athletes.aid AND (Epreuves.nom ='400MH' OR Epreuves.nom = '400MF') AND Athletes.nationalite = Pays.pid);

--3
SELECT DISTINCT Athletes.prenom, Athletes.nom, AthLetes.naissance
FROM Athletes, Equipes
WHERE (DATE_PART('year',current_date::date) - DATE_PART('year',Athletes.naissance::date) < 25) AND Athletes.equipe = 6;

--4
SELECT Medailles.type, Epreuves.nom, Resultats.temps
FROM Epreuves, Medailles, Athletes, Resultats, Matchs
WHERE Medailles.gagnant = Athletes.aid AND Athletes.nom = 'Phelps' AND Athletes.prenom = 'Michael'
AND Epreuves.epid = Medailles.epreuve AND Matchs.epreuve = Epreuves.epid AND Matchs.tour = TRUE
AND Resultats.match = Matchs.maid AND Resultats.participant = Athletes.aid;

--5
SELECT nom
FROM Sports
WHERE individuel = TRUE;

--6
SELECT MIN(temps)
FROM Resultats, Matchs, Epreuves
WHERE Resultats.match = Matchs.maid AND Matchs.epreuve = Epreuves.epid AND Epreuves.nom = 'MarathonH';

--Difficulté 2

--1
SELECT Pays.nom, AVG(temps)
FROM Resultats, Matchs, Epreuves, Pays, Athletes
WHERE Resultats.match = Matchs.maid AND Matchs.epreuve = Epreuves.epid AND (Epreuves.nom = '200MnageH' or Epreuves.nom = '200MnageF')
AND Resultats.participant = Athletes.aid AND Athletes.nationalite = Pays.pid
GROUP BY Pays.nom;

--2
SELECT Pays.nom, COUNT(Medailles.mid) / 12 AS nombre--ici, on divise par 12 car pour une raison que l'on ignore, la requêtes compte 12 pour une médaille (au lieu de 1)
FROM Pays, Medailles, Athletes, Equipes
WHERE (Medailles.gagnant = Athletes.aid AND Athletes.nationalite = Pays.pid) 
OR (Medailles.equipegagnante = Equipes.eid AND Equipes.nationalite = Pays.pid)
GROUP BY Pays.nom;

--3
SELECT Epreuves.nom, Medailles.type, Athletes.nom, Athletes.prenom
FROM Epreuves, Athletes, Medailles
WHERE Medailles.epreuve = Epreuves.epid AND Medailles.gagnant = Athletes.aid AND (Medailles.type = 'or' OR Medailles.type = 'argent');

--4, Cette fonction enclenche un petit problème qui fait que les athlètes sont bien affichés, mais il faut ensuite appuiyer sur la touche "Q", qui va sauter cette requêtes et affiché les autres 
--car il est afficher (END) à la fin de l'affichage des athlètes, ce qui stop l'affichage des autres requêtes, car il y a trop d'athlètes sans médailles dans notre table (49)
SELECT Athletes.prenom, Athletes.nom
FROM Athletes
WHERE Athletes.aid NOT IN(SELECT Athletes.aid
			 			  FROM Athletes, Medailles, Equipes
			 			  WHERE Medailles.type = 'or' 
			 			  AND (Medailles.gagnant = Athletes.aid OR Medailles.equipegagnante = Athletes.equipe));

--5
SELECT DISTINCT Sports.nom
FROM Sports, Pays
WHERE Sports.individuel = TRUE AND Sports.sid NOT IN(SELECT Sports.sid
						FROM Sports, Pays, Athletes, Medailles, Epreuves
						WHERE Pays.nom = 'France' AND Medailles.gagnant = Athletes.aid AND Athletes.nationalite = Pays.pid
						AND Medailles.epreuve = Epreuves.epid AND Epreuves.type = Sports.sid);

--6
SELECT DISTINCT Athletes.nom, Athletes.prenom
FROM Athletes, Resultats, Epreuves, Matchs
WHERE Resultats.participant = Athletes.aid AND Resultats.match = Matchs.maid 
AND Matchs.epreuve = Epreuves.epid AND (Epreuves.nom = '100MH' or Epreuves.nom = '100MF') AND Resultats.temps < '00:00:10';

--Difficulté 3

--3
SELECT DISTINCT Sports.nom, COUNT(Epreuves.type)
FROM Sports, Epreuves
WHERE Sports.sid = Epreuves.type
GROUP BY Sports.nom
ORDER BY COUNT (Epreuves.type) ASC
LIMIT 5;

--4
SELECT (COUNT(Medailles.mid) / CAST ((SELECT COUNT(*) FROM Medailles) AS FLOAT)) * 100 AS Pourcentage_de_femmes
FROM Medailles, Epreuves
WHERE Medailles.epreuve = Epreuves.epid AND Epreuves.sexe = 'Femme';

--6
SELECT Pays.nom, COUNT(Medailles.mid) / 12 AS nombre--même raison que la question 2, difficulté 2
FROM Pays, Medailles, Athletes, Equipes
WHERE ((medailles.gagnant = Athletes.aid AND Athletes.nationalite = Pays.pid)
OR (Medailles.equipegagnante = Equipes.eid AND Equipes.nationalite = Pays.pid))
GROUP BY Pays.nom
HAVING COUNT(medailles.mid) > (SELECT COUNT(medailles.mid)
							   FROM Pays, Athletes, Medailles, Equipes
							   WHERE Pays.nom = 'France' AND ((Medailles.gagnant = Athletes.aid AND Athletes.nationalite = Pays.pid) 
							   OR (Medailles.equipegagnante = Equipes.eid AND Equipes.nationalite = Pays.pid)));

--3 Requetes supplémentaires

--Pays qui n'on pas gagné de medailles d'athlétisme
SELECT Pays.nom
FROM Pays
WHERE Pays.nom NOT IN (SELECT Pays.nom
			           FROM Pays, Medailles, Epreuves, Athletes, Sports
			  		   WHERE Medailles.epreuve = Epreuves.epid AND Epreuves.type = Sports.sid AND Sports.nom = 'Athletisme' 
			           AND medailles.gagnant = Athletes.aid AND Athletes.nationalite = Pays.pid);

--Pourcentage de médailles remporté par la France
SELECT ((COUNT(Medailles.mid) / 12) / CAST ((SELECT COUNT(*) FROM Medailles) AS FLOAT)) * 100 AS Pourcentage_France
FROM Medailles, Athletes, Equipes, Pays
WHERE (Medailles.gagnant = Athletes.aid AND Athletes.nationalite = Pays.pid AND Pays.nom = 'France')
OR (Medailles.equipegagnante = Equipes.eid AND Equipes.nationalite = Pays.pid AND Pays.nom = 'France');

--Moyenne du temps réailiser au 100M par des Français agés de plus de 29 ans
SELECT AVG(Resultats.temps)
FROM Resultats, Athletes, Epreuves, Pays, Matchs
WHERE Resultats.match = Matchs.maid AND Matchs.epreuve = Epreuves.epid
AND (Epreuves.nom = '100MH' OR Epreuves.nom = '100MF') AND Resultats.participant = Athletes.aid 
AND Athletes.nationalite = Pays.pid AND Pays.nom = 'France';

--partie 4 requetes

--les deux endroit avec les deux plus petits indices
SELECT DISTINCT Lieux.nom, Lieux.indice
FROM Lieux
ORDER BY Lieux.indice ASC
LIMIT 2;

--les deux endroit avec les deux plus grands indices
SELECT DISTINCT Lieux.nom, Lieux.indice
FROM Lieux
ORDER BY Lieux.indice DESC
LIMIT 2;