SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--WHERE continent is not null
--ORDER BY 3,4


-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at the Total Cases vs Total Deaths in Italy
-- Shows likelihood of dying if you contract Covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE Location like 'Italy'
and continent is not null
ORDER BY 1,2


-- Looking at the Total Cases vs Population in Italy
-- Shows what percentage of population got Covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS infection_rate
FROM PortfolioProject..CovidDeaths
WHERE Location like 'Italy' 
and continent is not null
ORDER BY 1,2


-- Looking at Countries with Hightest Infenction Rate compared to Population

SELECT location AS country, population, MAX(total_cases) as total_infenction_count, MAX(total_cases/population)*100 as percent_infected_population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY percent_infected_population desc


-- Showing Countries with Highest Death Count per Population

SELECT location AS country, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count desc


-- LET'S BREAK THINGS DOWN BY CONTINENT



-- Showing the continents with the Highest Death Count per Population

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count desc


-- Values are not correct, let's try a different approach on the "continent" column

SELECT Location, population, MAX(cast(total_deaths as int)) as total_death_count, 
	MAX((total_deaths/population))*100 as max_death_percentage
From PortfolioProject..CovidDeaths
--Where continent is not null
where location in ('Asia', 'Africa', 'North America', 'South America', 'Europe')
Group by Location, population
order by total_death_count desc


-- Now values are correct, we can go on with GLOBAL NUMBERS

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- We can use both CONVERT and CAST for converting the new_vaccinations value to integer 
-- (in this case, considering the range reached by the values, we have to use BIGINT)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY dea.location,
	dea.date)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Here I received the following error: ORDER BY list of RANGE window frame has total size of 8010 bytes. Largest size supported is 900 bytes.
-- I fixed the error by modifing the 'location' column in the 'CovidDeaths' table

ALTER TABLE CovidDeaths ALTER COLUMN location nvarchar(150)


-- Now we can run the query without any issue

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY dea.location,
	dea.date) as rolling_people_vaccinated,
	(rolling_people_vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location,
	dea.date) as rolling_people_vaccinated
--,	(rolling_people_vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT*, (rolling_people_vaccinated/population)*100
FROM pop_vs_vac


-- TEMP TABLE

DROP TABLE if exists #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location,
	dea.date) as rolling_people_vaccinated
--,	(rolling_people_vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT*, (rolling_people_vaccinated/population)*100
FROM #percent_population_vaccinated


-- Creating View to store data for later visualizations

CREATE VIEW percent_population_vac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location,
	dea.date) as rolling_people_vaccinated
--,	(rolling_people_vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
FROM percent_population_vac