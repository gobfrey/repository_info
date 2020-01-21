$c->{repository_info_add_pair} = sub
{
	my ($pairs, $tag, $value,) = @_;

	return unless $value; #don't add empty values

	push @{$pairs}, [$tag, $value];
};

$c->{repository_info_generate_tag} = sub
{
	my ($category, $item, $modifier) = @_;

	foreach my $part ($category, $item, $modifier)
	{
		$part =~ s/_/-/g if $part;
	}

	my $tag = $category . '__' . $item;
	$tag .= '_' . $modifier if $modifier;

	return $tag;
};

$c->{repository_info_config} =
{
	'filename' => '_info.html',
	'categories' => [ 'repository','platform','capability','content', 'meta']
};

$c->{repository_info}->{repository} = sub
{
	my ($repo, $add_pair, $pairs) = @_;

	&{$add_pair}(['contact-email'], $repo->config('adminemail'));

	my $languages = $repo->get_conf('languages');
	&{$add_pair}(['interface-language','supported'],join(',', sort @{$languages}));
	&{$add_pair}(['interface-language','default'], $repo->config('defaultlanguage'));

	foreach my $language_id (sort @{$languages})
	{
		my $lang = $repo->get_language($language_id);
		next unless $lang->has_phrase('archive_name');
		&{$add_pair}(['name',$language_id],$lang->phrase('archive_name'));
	}	
};

$c->{repository_info}->{platform} =
[
		[['name'],'EPrints'],
		[['version'],EPrints->human_version()],
		[['url'],'http://eprints.org']
];

$c->{repository_info}->{capability} =
[
        [['oai-pmh'], 'supported'],
	[['oai-pmh','version'], '2.0'],
        [
		['oai-pmh','url'],
		sub {
        	        my ($repo) = @_;
        	        my $url = $repo->config('perl_url') . '/oai2';
        	        return $url;
        	}
	],
        [['sword'],'supported'],
	[['sword','version'] ,'2.0']
];

$c->{repository_info}->{content} = sub
{
	my ($repo, $add_pair) = @_;

	my $ds = $repo->dataset('repository');

	return unless $ds;

	my $counts = {};

	$ds->map($repo, sub
	{
		my ($repo, $ds, $dataobj, $counts) = @_;

		my $fulltext = 0;
		my $open_fulltext = 0;

		my @docs = $dataobj->get_all_documents(); 		
		if (scalar @docs > 0)
		{
			$fulltext = 1;
			foreach my $doc (@docs)
			{
				$open_fulltext = 1 if $doc->is_public;
			}
		}

		$counts->{all}->{'count-metadata'}++;
		$counts->{all}->{'count-fulltext'}++ if $fulltext;
		$counts->{all}->{'count-open-fulltext'}++ if $open_fulltext;

		my $type = $dataobj->value('type');
		if ($type)
		{
			$counts->{'type-'.$type}->{'count-metadata'}++;
			$counts->{'type-'.$type}->{'count-fulltext'}++ if $fulltext;
			$counts->{'type-'.$type}->{'count-open-fulltext'}++ if $open_fulltext;

		}

	}, $counts);

	foreach my $item (sort keys %{$counts})
	{
		foreach my $modifier ('count-metadata', 'count-fulltext','count-open-fulltext')
		{
			my $count = $counts->{$item}->{$modifier};
			&{$add_pair}([$item,$modifier], ($count?$count:0));
		}

	}


};

$c->{repository_info}->{meta} =
[
	[['datestamp'], EPrints::Time::iso_date()],
	[['version'], '0.1.3']
];

