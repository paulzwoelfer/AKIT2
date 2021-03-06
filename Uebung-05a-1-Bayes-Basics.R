# AKIT2, Arno Hollosi
# �bung: Bayes
library(akit2)

# 1) Bei einer Serie von M�nzw�rfen erhalten wir 3x Kopf in 10 W�rfen.
#    Zeichnen Sie ein Diagramm f�r den Posterior, wenn ein uniformer
#    Prior verwendet wird und zeichnen Sie das 75%-HDI ein.
#    Tipp: Sehen Sie sich �hnliche Berechnungen im Source-Code 
#          des Arbeitsblatts an. Verwenden Sie aber 500 Punkte
#          und type="l" f�r den Plot.
theta = seq(0, 1, length.out = 500) #Wahrscheinlichkeit das ein bestimmter Wert eintritt
prior = rep(1/500, 500) #1 = 100%. Diese teilen wir gleichm��ig auf 500 Werte auf.
likelihood = dbinom(3, 10, theta)
posterior = prior * likelihood
posterior = posterior / sum(posterior)
plot(theta, posterior, type = "l", col = "green")
showHDI(theta, posterior, 0.75)

# 2) Nehmen Sie den Posterior aus (1) als neuen Prior und
#    berechnen Sie die Posterior-Verteilung f�r 27x Kopf bei 40 W�rfen.
#    Diagramm + 75%-HDI
prior = posterior
likelihood = dbinom(27, 40, theta)
posterior = prior * likelihood
posterior = posterior / sum(posterior)
plot(theta, posterior, type = "l", col = "blue")
showHDI(theta, posterior, 0.75)

# 3) Vergleichen Sie das so erzeugte Diagramm mit folgender Serie:
#    uniformer Prior, N=50, z=30
#    Welchen Schluss ziehen Sie daraus?
prior = rep(1/500, 500)
likelihood = dbinom(30, 50, theta)
posterior = prior * likelihood
posterior = posterior / sum(posterior)
plot(theta, posterior, type = "l", col = "yellow")
showHDI(theta, posterior, 0.75)

# 4) Vergleichen Sie folgende zwei Ergebnisse:
# a) Zuerst uniformer Prior, N=20, z=12; dann
#    resultierenden Posterior als Prior n�tzen f�r N=30, z=20
# b) Zuerst uniformer Prior, N=30, z=20; dann
#    resultierenden Posterior als Prior n�tzen f�r N=20, z=12
# Welchen Schluss ziehen Sie daraus?
# Warum entsteht dieser Zusammenhang?
prior = rep(1/500, 500)
likelihood = dbinom(12, 20, theta)
posterior = likelihood * prior
posterior = posterior / sum(posterior)
prior = posterior
likelihood = dbinom(20, 30, theta)
posterior = prior * likelihood
posterior = posterior / sum(posterior)
plot(theta, posterior, type = "l", col = "darkgreen")
showHDI(theta, posterior, 0.75)

prior = rep(1/500, 500)
likelihood = dbinom(20, 30, theta)
posterior = likelihood * prior
posterior = posterior / sum(posterior)
prior = posterior
likelihood = dbinom(12, 20, theta)
posterior = prior * likelihood
posterior = posterior / sum(posterior)
plot(theta, posterior, type = "l", col = "darkgreen")
showHDI(theta, posterior, 0.75)

#Beides exakt das gleiche.

# 5) Gegeben sei die Datenreihe y ~ Poisson(1000).
#    Die Poisson-Verteilung wird häufig f�r ganzzahlige Ereignisse
#    (z.B. Anzahl Goldmedaillien, Anzahl Unf�lle etc.) verwendet.
#    Berechnen Sie mit Hilfe von Bayes die Posterior-Verteilung
#    und 95%-HDI f�r den Mittelwert der Population auf Basis der
#    Datenreihe mit uniformen Prior f�r den Bereich 950:1050.
#    Die Likelihood-Funktion f�r eine Poisson-Verteilung ist als
#    Hilfestellung vorgegeben.
set.seed(1234)
daten = rpois(30, 1000)

# data ... Messreihe
# parameter ... zu berechnender Wertebereich (Sequenz) für Poisson-Mittelwert
pois.likelihood = function(data, parameter) {
  dist = rep(1, length(parameter))
  for (y in data) {
    # die einzelnen Wahrscheinlichkeiten multiplizieren sich auf,
    # weil die einzelnen Messwerte unabh�ngig voneinander sind
    dist = dist * dpois(y, parameter)
  }
  return(dist)
}

lambda = 950:1050
prior = rep(1/101, 101)
likelihood = pois.likelihood(daten, lambda)
posterior = prior * likelihood
posterior = posterior / sum(posterior)
plot(lambda, posterior, type = "l", col = "darkgreen")
showHDI(lambda, posterior, 0.95)
