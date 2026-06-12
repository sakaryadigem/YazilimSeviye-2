<?php

	$isim_soyisim 	= $_POST["isim"];
	$cinsiyet 		= $_POST["cinsiyet"];
	
	$image 		= file_get_content($_FILES['image']['tmp_name']);
	$image_name = $FILES['image']['name'];
	$image_size = getimagesize($_FILES['image']['tmp_name']);

	echo "<b>İsim:</b> ".$isim_soyisim."<br>";
	echo "<b>Cinsiyet:</b> ".$cinsiyet."<br>";
	echo "<b>Resim:</b>".$image_name." Boyut: ".$image_size."<img src=".$image."><br>";
?>