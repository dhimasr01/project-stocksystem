CREATE TABLE `stocksystem` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `item` varchar(50) NOT NULL,
    `stock` int(11) NOT NULL,
    PRIMARY KEY (`id`)
);

INSERT INTO `stocksystem` (`item`, `stock`) VALUES
('tosti', 10),
('water_bottle', 20);
